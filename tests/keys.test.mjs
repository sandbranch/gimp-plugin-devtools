// Unit tests for gui/keys.mjs: the key events must be ones that GTK's
// Broadway page turns into the right keysyms. Prints PASS or FAIL per case.
import { charEvents, keyEvents, textEvents, keyNames } from '../gui/keys.mjs';

let fails = 0;
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'} keys: ${name}${ok || !detail ? '' : `\n  ${detail}`}`);
  if (!ok) fails++;
};

// the virtual key codes that Broadway's page handles on keydown instead of
// waiting for the character (specialKeyTable in broadway.js of GTK 3)
const special = new Set([8, 13, 9, 27, 46, 36, 35, 33, 34, 45, 37, 38, 39, 40,
  16, 17, 18, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123]);

// every printable ASCII character is a keyDown with that text, with a key
// code that Broadway does not take for a special key, and a keyUp with the
// same key code (Broadway pairs them by it)
const bad = [];
for (let c = 32; c < 127; c++) {
  const ch = String.fromCharCode(c);
  const [down, up, ...rest] = charEvents(ch);
  const ok = down.type === 'keyDown' && down.text === ch && down.key === ch &&
    !special.has(down.windowsVirtualKeyCode) && up.type === 'keyUp' &&
    up.windowsVirtualKeyCode === down.windowsVirtualKeyCode && rest.length === 0;
  if (!ok) bad.push(JSON.stringify(ch));
}
check('all printable ASCII types its character', bad.length === 0, `wrong: ${bad.join(' ')}`);

// the letters p to z once had the key codes of F1 to F12
check('p has the key code of P, not F1', charEvents('p')[0].windowsVirtualKeyCode === 80);
check('letters and digits have their key codes',
  [...'azAZ09'].every(ch => charEvents(ch)[0].windowsVirtualKeyCode === ch.toUpperCase().charCodeAt(0)));

// named keys have the key codes of Broadway's table
const codes = { Backspace: 8, Tab: 9, Enter: 13, Escape: 27, Delete: 46, Home: 36, End: 35,
  PageUp: 33, PageDown: 34, Insert: 45, Left: 37, Up: 38, Right: 39, Down: 40,
  ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39, ArrowDown: 40, F1: 112, F12: 123 };
for (const [name, vk] of Object.entries(codes)) {
  const [down, up] = keyEvents(name);
  check(`key ${name} is code ${vk}`, down.type === 'rawKeyDown' && down.windowsVirtualKeyCode === vk &&
    up.type === 'keyUp' && up.windowsVirtualKeyCode === vk, JSON.stringify(down));
}
check('arrow keys use the DOM key names', keyEvents('Left')[0].key === 'ArrowLeft');

// Backspace once got the key code of B from its first letter
check('Backspace is not B', keyEvents('Backspace')[0].windowsVirtualKeyCode === 8);

// a single character and Space are typed, so Broadway sees their keypress
check('key:a types a', keyEvents('a')[0].type === 'keyDown' && keyEvents('a')[0].text === 'a');
check('key:Space types a space', keyEvents('Space')[0].text === ' ');

// unknown names are an error, not a stray letter
let threw = false;
try { keyEvents('Bogus'); } catch { threw = true; }
check('unknown key name is an error', threw);
check('every listed key name works', keyNames.every(n => keyEvents(n).length === 2));

// text: newline and tab are Enter and Tab; other characters as they are
const t = textEvents('a\nb\tä€');
check('text newline is Enter', t[2].windowsVirtualKeyCode === 13 && t[2].type === 'rawKeyDown');
check('text tab is Tab', t[6].windowsVirtualKeyCode === 9);
check('text non-ASCII is typed', t[8].text === 'ä' && t[10].text === '€');
check('text of astral characters is one key each', textEvents('😀').length === 2);

process.exit(fails ? 1 : 0);
