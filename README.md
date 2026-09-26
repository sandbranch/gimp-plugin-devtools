# gimp-plugin-devtools

Scripts for building and testing GIMP 3 plug-ins and GEGL operations,
especially against the Flatpak version of GIMP, used for the plug-ins under
[github.com/sandbranch](https://github.com/sandbranch).

Where that work stands and what comes next: [STATUS.md](STATUS.md).

## What you need

- A POSIX shell (the scripts are `/bin/sh`, tested with dash, bash and
  BusyBox).
- Either the Flatpak GIMP and the GNOME SDK it was built with:

      flatpak install flathub org.gimp.GIMP
      gimp-build.sh --env        # shows GIMP_SDK, e.g. org.gnome.Sdk/x86_64/50
      flatpak install flathub org.gnome.Sdk//50

  (`gimp-build.sh` tells you the exact command if the SDK is missing), or a
  native GIMP 3 with its development files (`gimp-console` or `gimp` on the
  `PATH`, plus a compiler, meson and ninja).
- For `gui/cdp.mjs`: node 22 or later and Google Chrome or Chromium.

## gimp-build.sh

Runs a build command in a source folder against the GIMP that will run the
result:

    gimp-build.sh <source folder> <command...>
    gimp-build.sh --env        # print what it found, build nothing

With the Flatpak `org.gimp.GIMP` the command runs inside the Flatpak with
the GNOME SDK that GIMP was built with, so the result links against the
libraries of the Flatpak. The script reads the SDK from
`flatpak info org.gimp.GIMP` and tells you how to install it if it is
missing. Without the Flatpak (or with `GIMP_FLATPAK=0`) the command runs
natively. The exit code is that of the command.

Two variables are set for the command; escape the `$` so that they are
expanded there:

- `$GIMP_PLUGINDIR`: the user's plug-in folder, e.g.
  `~/.config/GIMP/3.2/plug-ins` (the Flatpak shares it); under
  `$XDG_CONFIG_HOME` if that is set, or `$GIMP3_DIRECTORY/plug-ins` if that
  is set, as GIMP itself does
- `$GEGL_OPDIR`: the user's folder for GEGL operations,
  `~/.local/share/gegl-0.4/plug-ins`; for the Flatpak
  `~/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins`

Examples, from a plug-in's source folder:

    gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
    gimp-build.sh . ninja -C build install

    # a GEGL operation
    gimp-build.sh . meson setup build -Dmoduledir=\$GEGL_OPDIR

Each argument of the command stays one word, so paths with spaces work
(`gimp-build.sh "$src" meson setup "$out/build"`). A command given as a
single argument is run as a shell command line, for `&&`, pipes or
redirections:

    gimp-build.sh . 'meson setup build && ninja -C build install'

Settings, from the environment:

- `GIMP_FLATPAK`: `1` to use the Flatpak, `0` for the native GIMP; unset,
  the Flatpak is used if it is installed
- `GIMP_APP_ID`: the Flatpak, `org.gimp.GIMP` by default

## gimp-env.sh

Shared settings for the scripts, sourced by them: whether GIMP is the
Flatpak, its version and SDK, and the two folders above. Sourcing it never
exits your shell; if no GIMP 3 is found, `$GIMP_ENV_ERROR` says why.

## gui/cdp.mjs

Drives a page in a headless Chrome over the DevTools protocol: navigate,
click, type, press keys and take screenshots. With GTK's Broadway backend
GIMP draws into a web page, so dialogs can be tested and screenshotted
without a display:

    # GIMP on a Broadway display, running a Python script (e.g. one that
    # opens an image and a plug-in dialog); broadwayd stops with GIMP
    flatpak run --env=GDK_BACKEND=broadway --env=BROADWAY_DISPLAY=:5 \
      --command=sh org.gimp.GIMP -c \
      "broadwayd --port 8085 :5 & bw=\$!; sleep 2; gimp-3.2 --no-splash \
       --batch-interpreter python-fu-eval -b \"exec(open('script.py').read())\"; \
       kill \$bw" &

    # a headless Chrome to look at it
    google-chrome --headless=new --remote-debugging-port=9333 \
      --user-data-dir=/tmp/cdp-chrome --password-store=basic about:blank &

    node gui/cdp.mjs size:1600,1000 nav:http://127.0.0.1:8085/ wait:6000 shot:dialog.png
    node gui/cdp.mjs click:552,691 wait:2000 shot:after.png

    kill %2    # the Chrome, when done; GIMP quits when you close it

`gimp-3.2` is the GIMP of the Flatpak; `gimp-build.sh --env` shows the
version. Without `--password-store=basic` a new Chrome can wait some 25
seconds for a keyring on its first page load, longer than a short `wait:`.

Actions:

- `nav:url`, `size:w,h` (of the page), `wait:ms`, `shot:file.png`
- `click:x,y`, `down:x,y` and `up:x,y` (press and hold, release),
  `move:x,y`
- `key:Name`: Enter, Tab, Escape, Backspace, Delete, Insert, Home, End,
  PageUp, PageDown, Left, Right, Up, Down, F1 to F12, Space, or a single
  character
- `text:abc`: types the text; a newline is Enter, a tab is Tab
- `eval:expression`: prints the value of a JavaScript expression in the
  page

All actions are checked before any is run; an unknown one is an error.
Settings, from the environment: `CDP_PORT`, the Chrome's debugging port
(9333); `CDP_TIMEOUT`, how long to wait for Chrome to answer, in ms
(30000).

Close a running GIMP of yours first: a second GIMP hands its work over to
the running one.

## Tests

    tests/run.sh

Checks the scripts with shellcheck, `gimp-build.sh` and `gimp-env.sh`
against a fake `flatpak` and a fake native GIMP in a throwaway HOME (native,
Flatpak, no GIMP, GIMP 2, missing SDK, translated `flatpak info`, paths with
spaces), the key events of `cdp.mjs`, `cdp.mjs` against a headless Chrome,
and typing into a GTK text field on Broadway. What is not installed
(shellcheck, node 22, Chrome, the Flatpak GIMP) is skipped. Needs no
network and touches nothing outside a temporary folder.

## License

GPL version 3 or later.
