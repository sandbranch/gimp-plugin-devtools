#!/bin/sh
# Shared settings for the scripts of gimp-plugin-devtools; source it.
#
# GIMP is the Flatpak org.gimp.GIMP if it is installed, otherwise the gimp
# on the PATH. Set GIMP_FLATPAK=0 to use the native GIMP even when the
# Flatpak is installed, or GIMP_FLATPAK=1 to insist on the Flatpak.
#
# Sets GIMP_FLATPAK, GIMP_VERSION, GIMP_SERIES, GIMP_SDK (Flatpak only),
# GIMP_PLUGINDIR and GEGL_OPDIR. Sourcing it never exits the shell: if GIMP
# cannot be found, GIMP_ENV_ERROR says why and the scripts stop with it.

# the variables are used by the scripts that source this one
# shellcheck disable=SC2034

GIMP_APP_ID=${GIMP_APP_ID:-org.gimp.GIMP}
GIMP_ENV_ERROR=
GIMP_VERSION=
GIMP_SDK=

have_flatpak_gimp () {
    command -v flatpak >/dev/null 2>&1 && flatpak info "$GIMP_APP_ID" >/dev/null 2>&1
}

GIMP_FLATPAK_FORCED=$GIMP_FLATPAK
if [ -z "$GIMP_FLATPAK" ]; then
    if have_flatpak_gimp; then
        GIMP_FLATPAK=1
    else
        GIMP_FLATPAK=0
    fi
fi

# the labels of flatpak info are translated, so read them in the C locale
if [ "$GIMP_FLATPAK" = 1 ]; then
    if ! command -v flatpak >/dev/null 2>&1; then
        GIMP_ENV_ERROR="GIMP_FLATPAK=1 but flatpak is not installed"
    elif ! have_flatpak_gimp; then
        GIMP_ENV_ERROR="the Flatpak $GIMP_APP_ID is not installed; install it with
    flatpak install flathub $GIMP_APP_ID"
    else
        # e.g. "3.2.6" and "org.gnome.Sdk/x86_64/50"
        GIMP_VERSION=$(LC_ALL=C flatpak info "$GIMP_APP_ID" | sed -n 's/^ *Version: *//p')
        GIMP_SDK=$(LC_ALL=C flatpak info --show-sdk "$GIMP_APP_ID")
    fi
elif [ "$GIMP_FLATPAK" = 0 ]; then
    for gimp_cmd in gimp-console gimp; do
        if command -v "$gimp_cmd" >/dev/null 2>&1; then
            GIMP_VERSION=$(LC_ALL=C "$gimp_cmd" --version 2>/dev/null |
                sed -n 's/.* \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9.]*\).*/\1/p' | head -n 1)
            [ -n "$GIMP_VERSION" ] && break
        fi
    done
    unset gimp_cmd
    if [ -z "$GIMP_VERSION" ]; then
        if [ "$GIMP_FLATPAK_FORCED" = 0 ]; then
            GIMP_ENV_ERROR="GIMP_FLATPAK=0 but there is no gimp-console or gimp on the PATH"
        else
            GIMP_ENV_ERROR="no GIMP found: neither the Flatpak $GIMP_APP_ID nor gimp-console or gimp on the PATH; install GIMP 3, e.g. with
    flatpak install flathub $GIMP_APP_ID"
        fi
    fi
else
    GIMP_ENV_ERROR="GIMP_FLATPAK must be 0 (native GIMP), 1 (the Flatpak) or unset (either), not '$GIMP_FLATPAK'"
fi

if [ -z "$GIMP_ENV_ERROR" ] && [ -z "$GIMP_VERSION" ]; then
    GIMP_ENV_ERROR="could not read the version of the Flatpak $GIMP_APP_ID from flatpak info"
fi

# the series, which names the profile folder: 3.2.6 -> 3.2
GIMP_SERIES=$(echo "$GIMP_VERSION" | cut -d. -f1,2)

case $GIMP_SERIES in
    ''|[012].*) [ -n "$GIMP_ENV_ERROR" ] ||
        GIMP_ENV_ERROR="GIMP $GIMP_VERSION found, but these scripts are for GIMP 3" ;;
esac

# the user's folder for GIMP plug-ins; the Flatpak shares ~/.config/GIMP.
# GIMP3_DIRECTORY moves the whole profile, relative to the home folder
# unless it is an absolute path.
case $GIMP3_DIRECTORY in
    '') GIMP_PLUGINDIR="${XDG_CONFIG_HOME:-$HOME/.config}/GIMP/$GIMP_SERIES/plug-ins" ;;
    /*) GIMP_PLUGINDIR="$GIMP3_DIRECTORY/plug-ins" ;;
    *) GIMP_PLUGINDIR="$HOME/$GIMP3_DIRECTORY/plug-ins" ;;
esac

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
