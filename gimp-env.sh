#!/bin/sh
# Shared settings for the scripts of gimp-plugin-devtools; source it.
#
# GIMP is the Flatpak org.gimp.GIMP if it is installed, otherwise the gimp
# on the PATH. Set GIMP_FLATPAK=0 to use the native GIMP even when the
# Flatpak is installed.

GIMP_APP_ID=${GIMP_APP_ID:-org.gimp.GIMP}

if [ -z "$GIMP_FLATPAK" ]; then
    if command -v flatpak >/dev/null 2>&1 && flatpak info "$GIMP_APP_ID" >/dev/null 2>&1; then
        GIMP_FLATPAK=1
    else
        GIMP_FLATPAK=0
    fi
fi

if [ "$GIMP_FLATPAK" = 1 ]; then
    # e.g. "3.2.6" and "org.gnome.Sdk/x86_64/50"
    GIMP_VERSION=$(flatpak info "$GIMP_APP_ID" | sed -n 's/^ *Version: *//p')
    GIMP_SDK=$(flatpak info "$GIMP_APP_ID" | sed -n 's/^ *Sdk: *//p')
else
    GIMP_VERSION=$(gimp-console --version 2>/dev/null | sed -n 's/.*version \([0-9.]*\).*/\1/p')
fi

# the series, which names the profile folder: 3.2.6 -> 3.2
GIMP_SERIES=$(echo "$GIMP_VERSION" | cut -d. -f1,2)

# the user's folder for GIMP plug-ins; the Flatpak shares ~/.config/GIMP
GIMP_PLUGINDIR="${XDG_CONFIG_HOME:-$HOME/.config}/GIMP/$GIMP_SERIES/plug-ins"

# the user's folder for GEGL operations: inside the Flatpak it is its own
# data folder
if [ "$GIMP_FLATPAK" = 1 ]; then
    GEGL_OPDIR="$HOME/.var/app/$GIMP_APP_ID/data/gegl-0.4/plug-ins"
else
    GEGL_OPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/gegl-0.4/plug-ins"
fi

die () {
    echo "$(basename "$0"): $*" >&2
    exit 1
}
