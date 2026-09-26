#!/bin/sh
# Run a build command for a GIMP plug-in in the given source folder, against
# the GIMP that will run it.
#
# With the Flatpak GIMP the command runs inside it, with the GNOME SDK that
# GIMP was built with, so the result links against the libraries of the
# Flatpak. With a native GIMP it simply runs in the folder.
#
#   gimp-build.sh <source folder> <command...>
#   gimp-build.sh --env      # print the settings found, build nothing
#
# e.g.
#   gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
#   gimp-build.sh . ninja -C build install
#   gimp-build.sh . 'meson setup build && ninja -C build install'
#
# $GIMP_PLUGINDIR and $GEGL_OPDIR are the user's folders for plug-ins and
# GEGL operations; escape the $ so that they are expanded in the build
# environment. Each argument of the command stays one word, spaces and all;
# a command given as a single argument is run as a shell command line.

usage="usage: $(basename "$0") <source folder> <command...>
       $(basename "$0") --env"

case $1 in
    -h|--help) echo "$usage"; exit 0 ;;
esac

. "$(dirname "$0")/gimp-env.sh"

if [ "$1" = --env ]; then
    echo "GIMP_FLATPAK=$GIMP_FLATPAK"
    echo "GIMP_APP_ID=$GIMP_APP_ID"
    echo "GIMP_VERSION=$GIMP_VERSION"
    echo "GIMP_SDK=$GIMP_SDK"
    echo "GIMP_PLUGINDIR=$GIMP_PLUGINDIR"
    echo "GEGL_OPDIR=$GEGL_OPDIR"
    [ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"
    exit 0
fi

[ $# -ge 2 ] || die "$usage"
[ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"
dir=$(CDPATH='' cd -- "$1" && pwd) || die "no folder $1"
shift

# the command line for sh -c: a single argument as it is, otherwise each
# argument in double quotes, so that it stays one word but $VARIABLES in it
# are still expanded
if [ $# = 1 ]; then
    cmd=$1
else
    cmd=
    for arg; do
        arg=$(printf '%s\n' "$arg" | sed 's/[\\"`]/\\&/g')
        cmd="$cmd \"$arg\""
    done
    cmd=${cmd# }
fi

if [ "$GIMP_FLATPAK" = 0 ]; then
    cd "$dir" || die "cannot enter $dir"
    GIMP_PLUGINDIR=$GIMP_PLUGINDIR GEGL_OPDIR=$GEGL_OPDIR exec sh -c "$cmd"
fi

sdk_ref=$(echo "$GIMP_SDK" | awk -F/ '{print $1 "//" $3}')
if ! flatpak info "$sdk_ref" >/dev/null 2>&1; then
    # install it next to GIMP, from the remote GIMP came from
    origin=$(flatpak info --show-origin "$GIMP_APP_ID" 2>/dev/null)
    inst=$(LC_ALL=C flatpak info "$GIMP_APP_ID" | sed -n 's/^ *Installation: *//p')
    case $inst in
        system|user) inst=--$inst ;;
        ?*) inst=--installation=$inst ;;
    esac
    die "$GIMP_SDK, the SDK of the GIMP Flatpak, is not installed; install it with
    flatpak install $inst ${origin:-flathub} $sdk_ref"
fi

# inside the Flatpak, the data folder of the app is its XDG_DATA_HOME
# shellcheck disable=SC2016 # expanded by the sh inside the Flatpak
exec flatpak run --devel \
    --filesystem="$dir" \
    --filesystem=xdg-config/GIMP \
    --env=PKG_CONFIG_PATH=/app/lib/pkgconfig:/app/share/pkgconfig \
    --env=GIMP_PLUGINDIR="$GIMP_PLUGINDIR" \
    --command=sh "$GIMP_APP_ID" -c 'export GEGL_OPDIR="$XDG_DATA_HOME/gegl-0.4/plug-ins"; cd "$0" && sh -c "$1"' "$dir" "$cmd"
