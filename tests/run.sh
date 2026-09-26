#!/bin/sh
# Tests for gimp-plugin-devtools that need neither GIMP nor a network:
#
# - shellcheck on all shell scripts (skipped if it is not installed)
# - gimp-env.sh and gimp-build.sh against a fake flatpak and a fake native
#   GIMP in a throwaway HOME, for the native, Flatpak, missing GIMP and
#   missing SDK cases, with each POSIX shell found (dash, bash, busybox)
# - the key events of gui/cdp.mjs (skipped without node 22 or later)
# - gui/cdp.mjs against a headless Chrome (skipped without Chrome), and
#   typing into a GTK text field on Broadway (skipped without Chrome or the
#   Flatpak GIMP or broadwayd; takes a few seconds)
#
#   tests/run.sh
#
# Prints PASS, FAIL or SKIP per case and exits non-zero if any failed.
# Nothing outside a temporary folder is touched.

# the tests pass many $VARIABLES in single quotes on purpose, for
# gimp-build.sh to expand
# shellcheck disable=SC2016

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
top=$(dirname "$here")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/gimp-plugin-devtools-tests.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' INT TERM

fails=0
pass () { echo "PASS $*"; }
fail () { echo "FAIL $*"; fails=$((fails + 1)); }
skip () { echo "SKIP $*"; }

# check <name> <expected text> <actual text>
check () {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1"
        printf '  expected: %s\n  got:      %s\n' "$2" "$3"
    fi
}

# check_has <name> <expected substring> <actual text>
check_has () {
    case $3 in
        *"$2"*) pass "$1" ;;
        *) fail "$1"; printf '  expected to contain: %s\n  got: %s\n' "$2" "$3" ;;
    esac
}

# --- shellcheck ------------------------------------------------------------

if command -v shellcheck >/dev/null 2>&1; then
    if out=$(cd "$top" && shellcheck -x gimp-env.sh gimp-build.sh tests/run.sh tests/broadway.test.sh 2>&1); then
        pass "shellcheck"
    else
        fail "shellcheck"; echo "$out"
    fi
else
    skip "shellcheck (not installed)"
fi

# --- fake flatpak and GIMP ---------------------------------------------------
#
# FAKE_GIMP: where the GIMP Flatpak is installed (system, user) or empty
# FAKE_SDK: 1 if its SDK is installed
# flatpak info prints Spanish labels unless LC_ALL=C, like a real one

mkdir -p "$tmp/bin-flatpak" "$tmp/bin-native3" "$tmp/bin-native2" "$tmp/bin-none"
cat > "$tmp/bin-flatpak/flatpak" <<'EOF'
#!/bin/sh
case $1 in
info)
    shift
    what=all
    case $1 in --show-*) what=$1; shift ;; esac
    case $1 in
    org.gimp.GIMP) [ -n "$FAKE_GIMP" ] || exit 1 ;;
    org.gnome.Sdk//50) [ "$FAKE_SDK" = 1 ] && exit 0 || exit 1 ;;
    *) exit 1 ;;
    esac
    case $what in
    --show-sdk) echo org.gnome.Sdk/x86_64/50 ;;
    --show-origin) echo flathub ;;
    all)
        if [ "$LC_ALL" = C ]; then
            printf '          ID: org.gimp.GIMP\n     Version: 3.2.6\nInstallation: %s\n         Sdk: org.gnome.Sdk/x86_64/50\n' "$FAKE_GIMP"
        else
            printf '          ID: org.gimp.GIMP\n     Versión: 3.2.6\n  Instalación: %s\n         Sdk: org.gnome.Sdk/x86_64/50\n' "$FAKE_GIMP"
        fi ;;
    esac ;;
run)
    # run the command like the Flatpak would: with the --env settings and
    # the data folder of the app as XDG_DATA_HOME
    shift
    echo "$*" > "$FAKE_LOG"
    while :; do
        case $1 in
        --env=*) export "${1#--env=}" ;;
        --command=*) cmd=${1#--command=} ;;
        -*) ;;
        *) break ;;
        esac
        shift
    done
    app=$1; shift
    XDG_DATA_HOME="$HOME/.var/app/$app/data" exec "$cmd" "$@" ;;
*) exit 1 ;;
esac
EOF
printf '#!/bin/sh\necho "GNU Image Manipulation Program version 3.0.4"\n' > "$tmp/bin-native3/gimp-console"
printf '#!/bin/sh\necho "GNU Image Manipulation Program version 2.10.38"\n' > "$tmp/bin-native2/gimp"
chmod +x "$tmp"/bin-*/*

# a PATH with the basic tools but no real flatpak or gimp
mkdir -p "$tmp/bin-base"
for t in sh dirname basename cut sed awk head printf cat mkdir pwd env true false echo; do
    p=$(command -v "$t") && case $p in /*) ln -sf "$p" "$tmp/bin-base/$t" ;; esac
done

# run <PATH dirs...> -- <script and arguments...>: with the shell $shell,
# a clean environment and a HOME of its own, so that nothing of the real
# user is seen
run () {
    path=
    while [ "$1" != -- ]; do path="$path$tmp/$1:"; shift; done
    shift
    # shellcheck disable=SC2086 # $shell may be "busybox sh"
    env -i HOME="$tmp/home" PATH="$path$tmp/bin-base" FAKE_LOG="$tmp/flatpak.log" \
        FAKE_GIMP="$FAKE_GIMP" FAKE_SDK="$FAKE_SDK" ${XDG_CONFIG_HOME:+XDG_CONFIG_HOME="$XDG_CONFIG_HOME"} \
        ${GIMP_FLATPAK+GIMP_FLATPAK="$GIMP_FLATPAK"} ${GIMP3_DIRECTORY+GIMP3_DIRECTORY="$GIMP3_DIRECTORY"} \
        ${CDPATH:+CDPATH="$CDPATH"} $shell "$@" 2>&1
}

# the value of a variable in the output of gimp-build.sh --env
val () { printf '%s\n' "$2" | sed -n "s/^$1=//p"; }

build="$top/gimp-build.sh"
H="$tmp/home"
src="$tmp/source folder"
mkdir -p "$H" "$src"

shells=
for s in dash bash busybox; do
    command -v "$s" >/dev/null 2>&1 && shells="$shells $s"
done
[ -n "$shells" ] || shells='sh'

for shn in $shells; do
    # an absolute path, as the PATH of the tests has no shells
    shell=$(command -v "$shn")
    [ "$shn" = busybox ] && shell="$shell sh"

    unset GIMP_FLATPAK GIMP3_DIRECTORY XDG_CONFIG_HOME CDPATH
    FAKE_GIMP='' FAKE_SDK=''

    out=$(run bin-none -- "$build" --help); rc=$?
    check "$shn: --help exits 0" 0 "$rc"
    check_has "$shn: --help shows the usage" "usage:" "$out"

    out=$(run bin-native3 -- "$build" "$src"); rc=$?
    check "$shn: no command is an error" 1 "$rc"
    check_has "$shn: no command shows the usage" "usage:" "$out"

    # no GIMP at all
    out=$(run bin-none -- "$build" --env); rc=$?
    check "$shn: no GIMP fails" 1 "$rc"
    check_has "$shn: no GIMP says so" "no GIMP found" "$out"
    check_has "$shn: no GIMP says how to install it" "flatpak install flathub org.gimp.GIMP" "$out"
    out=$(run bin-none -- "$build" "$src" true); rc=$?
    check "$shn: no GIMP fails the build" 1 "$rc"

    # sourcing gimp-env.sh without GIMP must not exit the shell
    out=$(run bin-none -- -c '. "$0"; echo "still here: $GIMP_ENV_ERROR"' "$top/gimp-env.sh")
    check_has "$shn: sourcing without GIMP keeps the shell" "still here: no GIMP found" "$out"

    # native GIMP 3
    out=$(run bin-native3 -- "$build" --env)
    check "$shn: native GIMP_FLATPAK" 0 "$(val GIMP_FLATPAK "$out")"
    check "$shn: native GIMP_VERSION" 3.0.4 "$(val GIMP_VERSION "$out")"
    check "$shn: native GIMP_PLUGINDIR" "$H/.config/GIMP/3.0/plug-ins" "$(val GIMP_PLUGINDIR "$out")"
    check "$shn: native GEGL_OPDIR" "$H/.local/share/gegl-0.4/plug-ins" "$(val GEGL_OPDIR "$out")"

    XDG_CONFIG_HOME="$tmp/my config"
    out=$(run bin-native3 -- "$build" --env)
    check "$shn: native GIMP_PLUGINDIR with XDG_CONFIG_HOME" "$tmp/my config/GIMP/3.0/plug-ins" "$(val GIMP_PLUGINDIR "$out")"
    unset XDG_CONFIG_HOME

    GIMP3_DIRECTORY=/opt/gimp-profile
    out=$(run bin-native3 -- "$build" --env)
    check "$shn: GIMP3_DIRECTORY absolute" /opt/gimp-profile/plug-ins "$(val GIMP_PLUGINDIR "$out")"
    GIMP3_DIRECTORY=gimp-profile
    out=$(run bin-native3 -- "$build" --env)
    check "$shn: GIMP3_DIRECTORY relative to HOME" "$H/gimp-profile/plug-ins" "$(val GIMP_PLUGINDIR "$out")"
    unset GIMP3_DIRECTORY

    # native GIMP 2 is refused
    out=$(run bin-native2 -- "$build" "$src" true); rc=$?
    check "$shn: GIMP 2 fails" 1 "$rc"
    check_has "$shn: GIMP 2 says why" "for GIMP 3" "$out"

    # native builds: each argument stays a word, variables are expanded in
    # the build environment, a single argument is a shell command line
    out=$(run bin-native3 -- "$build" "$src" printf '[%s]' "two  words" '$GIMP_PLUGINDIR' 'q"u`o\te' '')
    check "$shn: native build arguments" "[two  words][$H/.config/GIMP/3.0/plug-ins][q\"u\`o\\te][]" "$out"
    out=$(run bin-native3 -- "$build" "$src" 'pwd && echo "$GEGL_OPDIR"')
    check "$shn: native build command line" "$src
$H/.local/share/gegl-0.4/plug-ins" "$out"
    run bin-native3 -- "$build" "$src" sh -c 'exit 7' >/dev/null; rc=$?
    check "$shn: native build exit code" 7 "$rc"
    out=$(run bin-native3 -- "$build" "$tmp/no such folder" true); rc=$?
    check "$shn: missing source folder fails" 1 "$rc"
    check_has "$shn: missing source folder says so" "no folder $tmp/no such folder" "$out"
    mkdir -p "$H/elsewhere/source folder"
    CDPATH="$H/elsewhere"
    out=$(cd "$tmp" && run bin-native3 -- "$build" "source folder" pwd)
    check "$shn: CDPATH does not change the source folder" "$src" "$out"
    unset CDPATH

    # Flatpak GIMP
    FAKE_GIMP=system FAKE_SDK=1
    out=$(run bin-flatpak bin-native3 -- "$build" --env)
    check "$shn: Flatpak GIMP_FLATPAK" 1 "$(val GIMP_FLATPAK "$out")"
    check "$shn: Flatpak GIMP_VERSION despite translated labels" 3.2.6 "$(val GIMP_VERSION "$out")"
    check "$shn: Flatpak GIMP_SDK" org.gnome.Sdk/x86_64/50 "$(val GIMP_SDK "$out")"
    check "$shn: Flatpak GIMP_PLUGINDIR" "$H/.config/GIMP/3.2/plug-ins" "$(val GIMP_PLUGINDIR "$out")"
    check "$shn: Flatpak GEGL_OPDIR" "$H/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins" "$(val GEGL_OPDIR "$out")"

    out=$(run bin-flatpak -- "$build" "$src" printf '[%s]' "two  words" '$GIMP_PLUGINDIR' '$GEGL_OPDIR' 'q"u`o\te')
    check "$shn: Flatpak build arguments" "[two  words][$H/.config/GIMP/3.2/plug-ins][$H/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins][q\"u\`o\\te]" "$out"
    check_has "$shn: Flatpak build runs with the SDK" "--devel " "$(cat "$tmp/flatpak.log")"
    check_has "$shn: Flatpak build can see the source folder" "--filesystem=$src" "$(cat "$tmp/flatpak.log")"
    out=$(run bin-flatpak -- "$build" "$src" pwd)
    check "$shn: Flatpak build runs in the source folder" "$src" "$out"
    run bin-flatpak -- "$build" "$src" sh -c 'exit 7' >/dev/null; rc=$?
    check "$shn: Flatpak build exit code" 7 "$rc"

    GIMP_FLATPAK=0
    out=$(run bin-flatpak bin-native3 -- "$build" --env)
    check "$shn: GIMP_FLATPAK=0 uses the native GIMP" 3.0.4 "$(val GIMP_VERSION "$out")"
    out=$(run bin-flatpak -- "$build" --env); rc=$?
    check "$shn: GIMP_FLATPAK=0 without a native GIMP fails" 1 "$rc"
    check_has "$shn: GIMP_FLATPAK=0 without a native GIMP says so" "GIMP_FLATPAK=0 but" "$out"
    GIMP_FLATPAK=yes
    out=$(run bin-flatpak -- "$build" "$src" true); rc=$?
    check "$shn: GIMP_FLATPAK=yes fails" 1 "$rc"
    check_has "$shn: GIMP_FLATPAK=yes says why" "GIMP_FLATPAK must be 0" "$out"
    GIMP_FLATPAK=1
    out=$(run bin-native3 -- "$build" "$src" true); rc=$?
    check "$shn: GIMP_FLATPAK=1 without flatpak fails" 1 "$rc"
    check_has "$shn: GIMP_FLATPAK=1 without flatpak says so" "flatpak is not installed" "$out"
    unset GIMP_FLATPAK

    # missing SDK: say how to install it, into the installation of GIMP
    FAKE_GIMP=user FAKE_SDK=0
    out=$(run bin-flatpak -- "$build" "$src" true); rc=$?
    check "$shn: missing SDK fails" 1 "$rc"
    check_has "$shn: missing SDK says how to install it" "flatpak install --user flathub org.gnome.Sdk//50" "$out"
    FAKE_GIMP=system
    out=$(run bin-flatpak -- "$build" "$src" true)
    check_has "$shn: missing SDK, system GIMP" "flatpak install --system flathub org.gnome.Sdk//50" "$out"
done

# --- gui/cdp.mjs -----------------------------------------------------------

# the node tests print PASS, FAIL and SKIP lines of their own
node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)
if [ "${node_major:-0}" -ge 22 ]; then
    for t in keys.test.mjs cdp.test.mjs; do
        out=$(node "$here/$t" 2>&1); rc=$?
        echo "$out"
        n=$(printf '%s\n' "$out" | grep -c '^FAIL')
        [ "$rc" = 0 ] || [ "$n" -gt 0 ] || n=1
        fails=$((fails + n))
    done
    out=$(sh "$here/broadway.test.sh" 2>&1); rc=$?
    echo "$out"
    [ "$rc" = 0 ] || fails=$((fails + 1))
else
    skip "gui/cdp.mjs tests (need node 22 or later)"
fi

if [ "$fails" = 0 ]; then
    echo "all passed"
else
    echo "$fails failed"
    exit 1
fi
