// Drive a headless Chrome page over the DevTools protocol.
// usage: node cdp.mjs nav:url size:w,h wait:ms click:x,y down:x,y up:x,y move:x,y
//                     key:Name text:abc shot:file.png eval:expression
// The Chrome is the one listening on 127.0.0.1:$CDP_PORT (default 9333);
// each step fails after $CDP_TIMEOUT ms (default 30000). Needs node 22 or
// later (for its WebSocket).
import { writeFileSync } from 'node:fs';
import { keyEvents, textEvents } from './keys.mjs';

const usage = `usage: node cdp.mjs <action>...
actions: nav:url size:w,h wait:ms click:x,y down:x,y up:x,y move:x,y
         key:Name text:abc shot:file.png eval:expression`;

const fail = msg => { console.error(`cdp.mjs: ${msg}`); process.exit(1); };

const port = Number(process.env.CDP_PORT || 9333);
const timeout = Number(process.env.CDP_TIMEOUT || 30000);
const args = process.argv.slice(2);
if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
  console.log(usage);
  process.exit(args.length === 0 ? 1 : 0);
}
if (typeof WebSocket === 'undefined') fail(`needs node 22 or later, this is ${process.version}`);
if (!Number.isInteger(port) || port <= 0) fail(`CDP_PORT is not a port: ${process.env.CDP_PORT}`);

// check all actions before doing any, so that a typo does not leave a half
// done run behind
const numbers = (v, n, a) => {
  const xs = v.split(',').map(Number);
  if (xs.length !== n || xs.some(x => !Number.isFinite(x))) fail(`${a}: needs ${n} number${n > 1 ? 's' : ''}`);
  return xs;
};
const steps = args.map(a => {
  const m = /^([a-z]+):(.*)$/s.exec(a);
  if (!m) fail(`not an action: ${a}\n${usage}`);
  const [, k, v] = m;
  switch (k) {
    case 'nav': case 'shot': case 'eval':
      if (!v) fail(`${a}: needs a value`);
      return { k, v };
    case 'size': return { k, v: numbers(v, 2, a) };
    case 'wait': return { k, v: numbers(v, 1, a)[0] };
    case 'click': case 'down': case 'up': case 'move': return { k, v: numbers(v, 2, a) };
    case 'key':
      try { return { k, v: keyEvents(v) }; } catch (e) { fail(`${a}: ${e.message}`); }
    case 'text': return { k, v: textEvents(v) };
    default: fail(`unknown action ${k}: ${a}\n${usage}`);
  }
});

const within = (p, what) => Promise.race([p, new Promise((_, no) =>
  setTimeout(() => no(new Error(`${what}: no answer from Chrome in ${timeout} ms`)), timeout).unref())]);

let tabs;
try {
  tabs = await within(fetch(`http://127.0.0.1:${port}/json`).then(r => r.json()), 'list of pages');
} catch (e) {
  fail(`no Chrome with remote debugging on port ${port} (${e.cause?.code || e.cause?.message || e.message}); start one with
  google-chrome --headless=new --remote-debugging-port=${port} --user-data-dir=/tmp/cdp-chrome about:blank &`);
}
const page = tabs.find(t => t.type === 'page' && t.webSocketDebuggerUrl);
if (!page) fail(`the Chrome on port ${port} has no page open`);

const ws = new WebSocket(page.webSocketDebuggerUrl);
let id = 0; const pend = {};
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id]; }
};
ws.onclose = () => { for (const r of Object.values(pend)) r({ error: { message: 'connection closed' } }); };
try {
  await within(new Promise((ok, no) => { ws.onopen = ok; ws.onerror = () => no(new Error('cannot connect')); }), 'connection');
} catch (e) { fail(e.message); }

const send = async (method, params = {}) => {
  const m = await within(new Promise(r => { pend[++id] = r; ws.send(JSON.stringify({ id, method, params })); }), method);
  if (m.error) throw new Error(`${method}: ${m.error.message}`);
  return m.result;
};

try {
  for (const { k, v } of steps) {
    if (k === 'nav') await send('Page.navigate', { url: v });
    else if (k === 'size') await send('Emulation.setDeviceMetricsOverride', { width: v[0], height: v[1], deviceScaleFactor: 1, mobile: false });
    else if (k === 'wait') await new Promise(r => setTimeout(r, v));
    else if (['click', 'down', 'up', 'move'].includes(k)) {
      const [x, y] = v;
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, button: 'none' });
      if (k === 'click' || k === 'down') await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
      if (k === 'click' || k === 'up') await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
    }
    else if (k === 'key' || k === 'text') for (const ev of v) await send('Input.dispatchKeyEvent', ev);
    else if (k === 'shot') {
      const r = await send('Page.captureScreenshot', { format: 'png' });
      writeFileSync(v, Buffer.from(r.data, 'base64'));
    }
    else if (k === 'eval') {
      const r = await send('Runtime.evaluate', { expression: v, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(`eval: ${r.exceptionDetails.exception?.description || r.exceptionDetails.text}`);
      console.log(typeof r.result.value === 'string' ? r.result.value : JSON.stringify(r.result.value));
    }
  }
} catch (e) {
  ws.close();
  fail(e.message);
}
ws.close();
process.exit(0);
