#!/bin/sh

OPWD="$PWD"
BASE="$(dirname "$(realpath "$0")")"
if [ "$OPWD" != "$BASE" ]; then
    echo "... $BASE is not the same as $PWD ..."
    echo "Going into $BASE and coming back here in a bit"
    cd "$BASE" || exit 1
fi
trap 'cd "$OPWD"' EXIT

# Function to log to stdout with green color
log() {
    _Xashstd_reset="\033[m"
    _Xashstd_color_code="\033[32m"
    printf "${_Xashstd_color_code}->${_Xashstd_reset} %s\n" "$*"
}

# Function to log_warning to stdout with yellow color
log_warning() {
    _Xashstd_reset="\033[m"
    _Xashstd_color_code="\033[33m"
    printf "${_Xashstd_color_code}->${_Xashstd_reset} %s\n" "$*"
}

# Function to log_error to stdout with red color
log_error() {
    _Xashstd_reset="\033[m"
    _Xashstd_color_code="\033[31m"
    printf "${_Xashstd_color_code}->${_Xashstd_reset} %s\n" "$*"
    exit 1
}

unnappear() {
	"$@" >/dev/null 2>&1
}

# Check if a dependency is available.
available() {
	unnappear which "$1" || return 1
}

# Exit if a dependency is not available
require() {
    available "$1" || log_error "[$1] is not installed. Please ensure the command is available [$1] and try again."
}

case "$1" in
"" | "build")
    require "${CC:=cc}" ; require make ; require bison
    log "Using make to build \"$(basename "$BASE")\""
    make -j"$(nproc)" || log_error "Make command failed" && {
        mv ./a.out ./awk
    }
    ;;
"clean")
    shift
    log "Starting clean process"
    make clean
    unnappear rm ./a.out ./awk
    log "Clean process completed"
    ;;
*)
    echo "Usage: $0 {build|clean}"
    exit 1
    ;;
esac
