#!/bin/sh
# End-to-end test of gui/cdp.mjs with GTK's Broadway backend: a GTK text
# field on a Broadway display (the broadwayd and GTK of the Flatpak GIMP, or
# of the system with GIMP_FLATPAK=0), a headless Chrome looking at it, and
# cdp.mjs typing into it. Checks that the field ends up with every printable
# ASCII character and that key: presses the keys it names.
#
# Prints PASS, FAIL or SKIP; exits non-zero on failure. Uses a free port and
# display of its own, so a running GIMP on Broadway is not disturbed.

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
top=$(dirname "$here")
cdp="$top/gui/cdp.mjs"

skip () { echo "SKIP broadway: $*"; exit 0; }

chrome=${CHROME:-}
for c in google-chrome google-chrome-stable chromium chromium-browser; do
    [ -n "$chrome" ] && break
    command -v "$c" >/dev/null 2>&1 && chrome=$c
done
[ -n "$chrome" ] || skip "no google-chrome or chromium (set CHROME)"
command -v node >/dev/null 2>&1 || skip "no node"

if [ "${GIMP_FLATPAK:-1}" = 1 ] && command -v flatpak >/dev/null 2>&1 &&
    flatpak info org.gimp.GIMP >/dev/null 2>&1; then
    flatpak=1
elif command -v broadwayd >/dev/null 2>&1 &&
    python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
    flatpak=0
else
    skip "neither the Flatpak org.gimp.GIMP nor broadwayd and python3-gi with GTK 3"
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/cdp-broadway.XXXXXX") || exit 1
free_port () {
    node -e 'const s = require("net").createServer().listen(0, "127.0.0.1", () => { console.log(s.address().port); s.close(); })'
}
bport=$(free_port)
cport=$(free_port)
display=$((40 + bport % 50))

cleanup () {
    touch "$tmp/quit"
    [ -n "$chrome_pid" ] && kill "$chrome_pid" 2>/dev/null
    [ -n "$gtk_pid" ] && wait "$gtk_pid" 2>/dev/null
    rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 1' INT TERM

# the GTK side: broadwayd, and the text field once the page is open
inner="broadwayd --port $bport :$display >'$tmp/broadwayd.log' 2>&1 & bw=\$!;
    python3 '$here/broadway-entry.py' '$tmp'; kill \$bw"
if [ "$flatpak" = 1 ]; then
    flatpak run --filesystem="$tmp" --filesystem="$here" --env=GDK_BACKEND=broadway \
        --env=BROADWAY_DISPLAY=":$display" --command=sh org.gimp.GIMP -c "$inner" &
else
    GDK_BACKEND=broadway BROADWAY_DISPLAY=":$display" sh -c "$inner" &
fi
gtk_pid=$!

"$chrome" --headless=new --remote-debugging-port="$cport" --user-data-dir="$tmp/chrome" \
    --no-first-run --no-default-browser-check --disable-gpu --password-store=basic about:blank >/dev/null 2>&1 &
chrome_pid=$!

# wait for both to listen
i=0
# (broadwayd by what it prints: after a connection of our own, it did not
# answer Chrome any more)
listening () {
    node -e 'fetch(process.argv[1]).then(() => process.exit(0), () => process.exit(1))' "$1"
}
until grep -q Listening "$tmp/broadwayd.log" 2>/dev/null &&
    listening "http://127.0.0.1:$cport/json/version"; do
    i=$((i + 1))
    [ $i -lt 100 ] || { echo "FAIL broadway: broadwayd or Chrome did not start"; exit 1; }
    sleep 0.2
done

export CDP_PORT="$cport" CDP_TIMEOUT=10000
node "$cdp" size:600,300 "nav:http://127.0.0.1:$bport/" wait:1500 || exit 1
touch "$tmp/go"
i=0
until [ "$(node "$cdp" 'eval:document.body.children.length')" -gt 0 ] 2>/dev/null; do
    i=$((i + 1))
    [ $i -lt 50 ] || { echo "FAIL broadway: the window did not show up"; exit 1; }
    sleep 0.2
done

ascii=$(node -e 'let s = ""; for (let c = 32; c < 127; c++) s += String.fromCharCode(c); process.stdout.write(s)')
# type everything, delete the ~, put an x before the }, delete the leading
# space and type non-ASCII text in front
node "$cdp" wait:1000 click:100,20 wait:300 "text:$ascii" key:Backspace key:Left key:x \
    key:Home key:Delete 'text:åé€' wait:1000 || exit 1
want="åé€$(printf '%s' "$ascii" | sed 's/^ //; s/}~$/x}/')"
got=$(cat "$tmp/value.txt" 2>/dev/null)
if [ "$got" = "$want" ]; then
    echo "PASS broadway: text and keys typed into a GTK field"
else
    echo "FAIL broadway: text and keys typed into a GTK field"
    printf '  expected: %s\n  got:      %s\n' "$want" "$got"
    exit 1
fi
