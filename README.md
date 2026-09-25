# gimp-plugin-devtools

Scripts for building and testing GIMP 3 plug-ins and GEGL operations,
especially against the Flatpak version of GIMP, used for the plug-ins under
[github.com/sandbranch](https://github.com/sandbranch).

## gimp-build.sh

Runs a build command in a source folder against the GIMP that will run the
result:

    gimp-build.sh <source folder> <command...>

With the Flatpak `org.gimp.GIMP` the command runs inside the Flatpak with
the GNOME SDK that GIMP was built with, so the result links against the
libraries of the Flatpak. The script finds the SDK version from
`flatpak info org.gimp.GIMP` and tells you how to install it if it is
missing. Without the Flatpak (or with `GIMP_FLATPAK=0`) the command runs
natively.

Two variables are set for the command; escape the `$` so that they are
expanded there:

- `$GIMP_PLUGINDIR`: the user's plug-in folder, e.g.
  `~/.config/GIMP/3.2/plug-ins` (the Flatpak shares it)
- `$GEGL_OPDIR`: the user's folder for GEGL operations; for the Flatpak
  `~/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins`

Examples, from a plug-in's source folder:

    gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
    gimp-build.sh . ninja -C build install

    # a GEGL operation
    gimp-build.sh . meson setup build -Dmoduledir=\$GEGL_OPDIR

## gimp-env.sh

Shared settings for the scripts, sourced by them: whether GIMP is the
Flatpak, its version and SDK, and the two folders above.

## gui/cdp.mjs

Drives a page in a headless Chrome over the DevTools protocol: navigate,
click, type, press keys and take screenshots. With GTK's Broadway backend
GIMP draws into a web page, so dialogs can be tested and screenshotted
without a display:

    # GIMP on a Broadway display, running a Python script (e.g. one that
    # opens an image and a plug-in dialog)
    flatpak run --env=GDK_BACKEND=broadway --env=BROADWAY_DISPLAY=:5 \
      --command=sh org.gimp.GIMP -c \
      "broadwayd --port 8085 :5 & sleep 2; gimp-3.2 --no-splash \
       --batch-interpreter python-fu-eval -b \"exec(open('script.py').read())\""

    # a headless Chrome to look at it
    google-chrome --headless=new --remote-debugging-port=9333 \
      --user-data-dir=/tmp/cdp-chrome about:blank &

    node gui/cdp.mjs size:1600,1000 nav:http://127.0.0.1:8085/ wait:6000 shot:dialog.png
    node gui/cdp.mjs click:552,691 wait:2000 shot:after.png

Actions: `nav:url`, `size:w,h`, `wait:ms`, `click:x,y`, `down:x,y`,
`up:x,y` (press and hold), `move:x,y`, `key:Name` (Tab, Enter, Escape,
arrows, Delete, letters), `text:abc`, `shot:file.png`.

Close a running GIMP of yours first: a second GIMP hands its work over to
the running one.

## License

GPL version 3 or later.
