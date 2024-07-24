#!/bin/sh

POSIXLY_CORRECT=1
cbuild_OPWD="$PWD"
BASE="$(realpath "$0")" && BASE="${BASE%/*}"
if [ "$OPWD" != "$BASE" ]; then
    cd "$BASE" || log "$R" "Unable to change directory to ${BASE##*/}. Re-execute using a POSIX shell and check again."
fi
trap 'cd "$cbuild_OPWD"' EXIT

# Color escape sequences
G="\033[32m" #     Green
R="\033[31m" #     Red
B="\033[34m" #     Blue
NC="\033[m"  #     Unset

log() {
    # shellcheck disable=SC2059 # Using %s with ANSII escape sequences is not possible
    printf "${1}->$NC "
    shift
    printf "%s\n" "$*"
}

require() {
    command -v "$1" >/dev/null 2>&1 || {
        log "$R" "[$1] is not installed. Please ensure the command is available [$1] and try again."
        exit 1
    }
}

run() {
    log "$B" "$*"
    # shellcheck disable=SC2068 # We want to split elements, but avoid whitespace problems (`$*`), and also avoid `eval $*`
    $@
}

: "${CC:=cc}"
build() {
    require "make"
    require "${CC}"
    log "$G" "Entering step: \"Build \"${BASE##*/}\" using \"$CC\""
    make -j"$(nproc)" || {
        log "$R" "Failed during step: \"Build \"${BASE##*/}\" using \"$CC\""
        exit 1
    }
}

# Argument processing
while [ $# -gt 0 ] || [ "$1" = "" ]; do
    case "$1" in
    "" | "build")
        # If the user doesn't use "build" explicitely, do not run the build step again.
        [ "$1" = "build" ] || {
            explicit="1"
        } && [ -n "$1" ] && shift
        if [ "$explicit" = "1" ]; then
            [ -f ./a.out ] || [ -f ./awk ] && log "$R" "Nothing to do; \"${BASE##*/}\" was already compiled" && exit 0
        fi
        # Start build process
        build && exit 0 || exit 1
        ;;
    "clean")
        shift
        run rm ./a.out ./awk 2>/dev/null
        exit 0
        ;;
    "retrieve")
        shift
        [ -x "./a.out" ] || [ -x ."/awk" ] && {
            log "$R" "\"${BASE##*/}\" was never compiled OR it was but its binaries weren't found anyways."
            exit 1
        } && mv ./a.out ./awk
        readlink -f ./awk
        exit 0
        ;;
    *)
        echo "Usage: $0 {build|clean}"
        exit 1
        ;;
    esac
done
