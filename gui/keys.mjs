// The DevTools key events for the key: and text: actions of cdp.mjs.
//
// GTK's Broadway page turns key events into keysyms like noVNC: keys it
// knows by their virtual key code (Enter, Tab, arrows, F1-F12, ...) on
// keydown, everything else from the character of the keypress event, which
// Chrome only sends for a keyDown with text. So a character must be a keyDown
// with text and a key code that is not one of the special ones: the lower
// case codes 112-123 are F1-F12, which would swallow p to {.

// name: [virtual key code, DOM key, DOM code]
const named = {
  Backspace: [8, 'Backspace', 'Backspace'],
  Tab: [9, 'Tab', 'Tab'],
  Enter: [13, 'Enter', 'Enter'],
  Escape: [27, 'Escape', 'Escape'],
  PageUp: [33, 'PageUp', 'PageUp'],
  PageDown: [34, 'PageDown', 'PageDown'],
  End: [35, 'End', 'End'],
  Home: [36, 'Home', 'Home'],
  Left: [37, 'ArrowLeft', 'ArrowLeft'],
  Up: [38, 'ArrowUp', 'ArrowUp'],
  Right: [39, 'ArrowRight', 'ArrowRight'],
  Down: [40, 'ArrowDown', 'ArrowDown'],
  Insert: [45, 'Insert', 'Insert'],
  Delete: [46, 'Delete', 'Delete'],
};
for (let i = 1; i <= 12; i++) named['F' + i] = [111 + i, 'F' + i, 'F' + i];
for (const [k, v] of Object.entries(named))
  if (v[1] !== k) named[v[1]] = v; // ArrowLeft as well as Left

export const keyNames = Object.keys(named).concat(['Space']);

// the virtual key code and DOM code of a character: those of the key of a
// letter or digit, 0 for anything else (the character is in the text)
function charCode(ch) {
  if (/^[a-z]$/i.test(ch)) return [ch.toUpperCase().charCodeAt(0), 'Key' + ch.toUpperCase()];
  if (/^[0-9]$/.test(ch)) return [ch.charCodeAt(0), 'Digit' + ch];
  if (ch === ' ') return [32, 'Space'];
  return [0, ''];
}

// the events that type one character
export function charEvents(ch) {
  if (ch === '\n' || ch === '\r') return keyEvents('Enter');
  if (ch === '\t') return keyEvents('Tab');
  const [vk, code] = charCode(ch);
  const common = { key: ch, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk };
  return [
    { type: 'keyDown', text: ch, unmodifiedText: ch, ...common },
    { type: 'keyUp', ...common },
  ];
}

// the events that press and release the key of that name (Enter, Tab,
// Escape, Backspace, Delete, Insert, Home, End, PageUp, PageDown, the
// arrows Left, Right, Up and Down, F1 to F12, Space) or of one character
export function keyEvents(name) {
  if (name === 'Space') return charEvents(' ');
  if ([...name].length === 1) return charEvents(name);
  const k = named[name];
  if (!k) throw new Error(`unknown key "${name}"; known are ${keyNames.join(', ')} and single characters`);
  const [vk, key, code] = k;
  const common = { key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk };
  return [{ type: 'rawKeyDown', ...common }, { type: 'keyUp', ...common }];
}

// the events that type a text
export function textEvents(text) {
  return [...text].flatMap(charEvents);
}
