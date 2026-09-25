// Drive a headless Chrome page over the DevTools protocol.
// usage: node cdp.mjs nav:url size:w,h wait:ms click:x,y down:x,y up:x,y move:x,y key:Name text:abc shot:file.png
const acts = process.argv.slice(2);
const tabs = await (await fetch('http://127.0.0.1:9333/json')).json();
const page = tabs.find(t => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r => ws.onopen = r);
let id = 0; const pend = {};
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id]; } };
const send = (method, params = {}) => new Promise(r => { pend[++id] = r; ws.send(JSON.stringify({ id, method, params })); });
const fs = await import('fs');
const keycodes = { Right: 39, Left: 37, Down: 40, Up: 38, Enter: 13, Escape: 27, Tab: 9, Delete: 46 };
for (const a of acts) {
  const [k, v] = a.split(/:(.*)/s);
  if (k === 'nav') await send('Page.navigate', { url: v });
  else if (k === 'size') { const [w, h] = v.split(',').map(Number); await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false }); }
  else if (k === 'wait') await new Promise(r => setTimeout(r, +v));
  else if (['click', 'down', 'up', 'move'].includes(k)) {
    const [x, y] = v.split(',').map(Number);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, button: 'none' });
    if (k === 'click' || k === 'down') await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    if (k === 'click' || k === 'up') await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  }
  else if (k === 'key') {
    const code = keycodes[v] || v.toUpperCase().charCodeAt(0);
    for (const type of ['rawKeyDown', 'keyUp'])
      await send('Input.dispatchKeyEvent', { type, key: v, code: v, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code });
  }
  else if (k === 'text') {
    for (const ch of v) {
      // virtual key codes are those of the upper case letter or digit: the
      // lower case codes 112-123 are F1-F12, which would swallow p to {
      const code = /[a-z0-9]/i.test(ch) ? ch.toUpperCase().charCodeAt(0) : 0;
      await send('Input.dispatchKeyEvent', { type: 'keyDown', key: ch, text: ch, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code });
      await send('Input.dispatchKeyEvent', { type: 'keyUp', key: ch, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code });
    }
  }
  else if (k === 'shot') { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(v, Buffer.from(r.result.data, 'base64')); }
}
ws.close(); process.exit(0);
