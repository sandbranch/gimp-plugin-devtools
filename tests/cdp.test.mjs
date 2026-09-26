// Tests gui/cdp.mjs against a headless Chrome on a page of its own (no
// network): typing, keys, clicks, eval and screenshots, and that the key
// events are the ones GTK's Broadway page needs. Skipped without Chrome;
// $CHROME names the browser if it is not google-chrome or chromium.
// Prints PASS, FAIL or SKIP per case.
import { spawn, spawnSync, execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, readFileSync, existsSync } from 'node:fs';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const cdp = join(dirname(fileURLToPath(import.meta.url)), '..', 'gui', 'cdp.mjs');
let fails = 0;
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'} cdp: ${name}${ok || !detail ? '' : `\n  ${detail}`}`);
  if (!ok) fails++;
};

// actions are checked before Chrome is needed
const bad = spawnSync(process.execPath, [cdp, 'clik:1,2'], { encoding: 'utf8', env: { ...process.env, CDP_PORT: '1' } });
check('unknown action is an error', bad.status === 1 && /unknown action clik/.test(bad.stderr), bad.stderr);
const badKey = spawnSync(process.execPath, [cdp, 'key:Bogus'], { encoding: 'utf8' });
check('unknown key is an error', badKey.status === 1 && /unknown key/.test(badKey.stderr), badKey.stderr);

const which = cmd => { try { return execFileSync('sh', ['-c', `command -v "${cmd}"`], { encoding: 'utf8' }).trim(); } catch { return ''; } };
const chrome = process.env.CHROME || ['google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser'].map(which).find(Boolean);
if (!chrome) {
  console.log('SKIP cdp: Chrome tests (no google-chrome or chromium; set CHROME)');
  process.exit(fails ? 1 : 0);
}

// a free port
const port = await new Promise(r => { const s = createServer().listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const noChrome = spawnSync(process.execPath, [cdp, 'wait:1'], { encoding: 'utf8', env: { ...process.env, CDP_PORT: String(port) } });
check('no Chrome is a clear error', noChrome.status === 1 && /no Chrome with remote debugging on port/.test(noChrome.stderr), noChrome.stderr);

const profile = mkdtempSync(join(tmpdir(), 'cdp-test-'));
const browser = spawn(chrome, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  '--no-first-run', '--no-default-browser-check', '--disable-gpu', '--password-store=basic', 'about:blank'], { stdio: 'ignore', detached: true });
const cleanup = () => {
  try { process.kill(-browser.pid, 'SIGKILL'); } catch {}
  try { rmSync(profile, { recursive: true, force: true, maxRetries: 5 }); } catch {}
};
process.on('exit', cleanup);
for (const s of ['SIGINT', 'SIGTERM']) process.on(s, () => process.exit(1));

// wait for it to listen
let up = false;
for (let i = 0; i < 100 && !up; i++) {
  try { await fetch(`http://127.0.0.1:${port}/json/version`); up = true; } catch { await new Promise(r => setTimeout(r, 100)); }
}
if (!up) { check('Chrome starts', false, `${chrome} did not listen on ${port}`); process.exit(1); }

const run = (...acts) => spawnSync(process.execPath, [cdp, ...acts], { encoding: 'utf8', timeout: 60000,
  env: { ...process.env, CDP_PORT: String(port), CDP_TIMEOUT: '10000' } });

// a page with a text field that logs the key events the way Broadway's page
// sees them, and a button that counts clicks
const html = `<input id=t autofocus style="position:absolute;left:10px;top:10px;width:300px">
<button id=b style="position:absolute;left:10px;top:60px;width:100px;height:40px" onclick="n++">b</button>
<script>
var n = 0, log = [];
for (const type of ['keydown', 'keypress', 'keyup'])
  document.addEventListener(type, e => log.push([type, e.keyCode, e.which, e.key]));
</script>`;
const nav = run('size:400,200', `nav:data:text/html,${encodeURIComponent(html)}`, 'wait:500',
  'click:100,20', 'eval:document.activeElement.id');
check('nav, click and eval', nav.status === 0 && nav.stdout.trim() === 't', nav.stderr || nav.stdout);

let ascii = '';
for (let c = 32; c < 127; c++) ascii += String.fromCharCode(c);
const typed = run(`text:${ascii}`, 'eval:document.getElementById("t").value');
check('text types all printable ASCII', typed.status === 0 && typed.stdout.replace(/\n$/, '') === ascii,
  typed.stderr || `got ${JSON.stringify(typed.stdout)}`);

// what Broadway needs: every character comes as a keypress with its
// character code, and no keydown has a key code of Broadway's special keys
const special = new Set([8, 13, 9, 27, 46, 36, 35, 33, 34, 45, 37, 38, 39, 40, 16, 17, 18,
  112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123]);
const log = JSON.parse(run('eval:JSON.stringify(log)').stdout);
const presses = log.filter(e => e[0] === 'keypress').map(e => String.fromCharCode(e[2])).join('');
check('every character is a keypress with its code', presses === ascii, `got ${JSON.stringify(presses)}`);
const specials = log.filter(e => e[0] === 'keydown' && special.has(e[1]));
check('no character looks like a special key to Broadway', specials.length === 0, JSON.stringify(specials));

const keys = run('eval:log.length = 0', 'key:End', 'key:Backspace', 'key:Left', 'key:x',
  'eval:document.getElementById("t").value.slice(-3)', 'eval:JSON.stringify(log.filter(e => e[0] === "keydown").map(e => e[1]))');
const [, tail, downs] = keys.stdout.trim().split('\n');
check('key: Backspace, Left and a letter', keys.status === 0 && tail === '|x}', keys.stderr || `got ${JSON.stringify(tail)}`);
check('key: key codes', downs === '[35,8,37,88]', `got ${downs}`);

const clicks = run('click:60,80', 'click:60,80', 'down:60,80', 'up:60,80', 'eval:n');
check('click and down/up', clicks.status === 0 && clicks.stdout.trim() === '3', clicks.stderr || clicks.stdout);

const png = join(profile, 'shot.png');
const shot = run(`shot:${png}`);
check('shot writes a PNG', shot.status === 0 && existsSync(png) &&
  readFileSync(png).subarray(1, 4).toString() === 'PNG', shot.stderr);

const thrown = run('eval:(() => { throw new Error("boom") })()');
check('a failing eval is an error', thrown.status === 1 && /boom/.test(thrown.stderr), thrown.stderr);

process.exit(fails ? 1 : 0);
