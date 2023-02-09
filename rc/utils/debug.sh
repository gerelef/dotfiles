#!/usr/bin/env bash

if [[ -n "$__BDEBUG_LOADED" ]]; then
    return 0
fi
readonly __BDEBUG_LOADED="__LOADED"
REQUIRE_DEPENDENCIES+="shellcheck "

bash-debug-subshell () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 1 ]] && echo "Single quote your entire argument." >&2 && return 2
    
    bash --norc <(echo "set -euxo pipefail; $@; exit 0")
}

shellcheck-bash () {
    [[ -z "$*" ]] && return 2
    
    \shellcheck --enable='add-default-case|avoid-nullary-conditions|check-unassigned-uppercase|deprecate-which|quote-safe-variables|require-variable-braces' --format tty --color=always --check-sourced -x --shell bash "$@"
}

# https://stackoverflow.com/a/57313672/10007109
timeit () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -lt 2 ]] && echo "Usage: timeit <num> <script> [<args>]" >&2 && return 2
    
    for i in `seq 1 $1`; do
        time "${@:2}"
    done 2>&1 |\
        grep ^real |\
        sed -r -e "s/.*real\t([[:digit:]]+)m([[:digit:]]+\.[[:digit:]]+)s/\1 \2/" |\
        awk '{sum += $1 * 60 + $2} END {print sum / NR}'
}

pid-of () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 1 ]] && echo "Only one argument." >&2 && return 2
    
    ps ax -e -o pid,comm | grep $1
}

export -f bash-debug-subshell
export -f shellcheck-bash
export -f timeit
export -f pid-of
