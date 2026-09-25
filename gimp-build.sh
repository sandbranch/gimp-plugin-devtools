#!/bin/sh
# Run a build command for a GIMP plug-in in the given source folder, against
# the GIMP that will run it.
#
# With the Flatpak GIMP the command runs inside it, with the GNOME SDK that
# GIMP was built with, so the result links against the libraries of the
# Flatpak. With a native GIMP it simply runs in the folder.
#
#   gimp-build.sh <source folder> <command...>
#
# e.g.
#   gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
#   gimp-build.sh . ninja -C build install
#
# $GIMP_PLUGINDIR and $GEGL_OPDIR are the user's folders for plug-ins and
# GEGL operations; escape the $ so that they are expanded in the build
# environment.

. "$(dirname "$0")/gimp-env.sh"

[ $# -ge 2 ] || die "usage: $(basename "$0") <source folder> <command...>"
dir=$(cd "$1" && pwd) || die "no folder $1"
shift

if [ "$GIMP_FLATPAK" = 0 ]; then
    cd "$dir" && GIMP_PLUGINDIR=$GIMP_PLUGINDIR GEGL_OPDIR=$GEGL_OPDIR sh -c "$*"
    exit $?
fi

sdk_ref=$(echo "$GIMP_SDK" | awk -F/ '{print $1 "//" $3}')
if ! flatpak info "$sdk_ref" >/dev/null 2>&1; then
    die "the SDK of the GIMP Flatpak is not installed; install it with
    flatpak install --user flathub $sdk_ref"
fi

# inside the Flatpak, the data folder of the app is its XDG_DATA_HOME
exec flatpak run --devel \
    --filesystem="$dir" \
    --filesystem=xdg-config/GIMP \
    --env=PKG_CONFIG_PATH=/app/lib/pkgconfig:/app/share/pkgconfig \
    --env=GIMP_PLUGINDIR="$GIMP_PLUGINDIR" \
    --command=sh "$GIMP_APP_ID" -c 'export GEGL_OPDIR="$XDG_DATA_HOME/gegl-0.4/plug-ins"; cd "$0" && sh -c "$1"' "$dir" "$*"
