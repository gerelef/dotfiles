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

shellcheck-bash () (
    [[ -z "$*" ]] && return 2
    
    \shellcheck --enable='add-default-case|avoid-nullary-conditions|check-unassigned-uppercase|deprecate-which|quote-safe-variables|require-variable-braces' --format tty --color=always --check-sourced -x --shell bash "$@"
)

# https://stackoverflow.com/a/57313672/10007109
timeit () (
    [[ -z "$*" ]] && return 2
    [[ "$#" -lt 2 ]] && echo "Usage: timeit <num> <script> [<args>]" >&2 && return 2
    
    for i in `seq 1 $1`; do
        time "${@:2}"
    done 2>&1 |\
        grep ^real |\
        sed -r -e "s/.*real\t([[:digit:]]+)m([[:digit:]]+\.[[:digit:]]+)s/\1 \2/" |\
        awk '{sum += $1 * 60 + $2} END {print sum / NR}'
)

_pid-of_completions () {
    # https://iridakos.com/programming/2018/03/01/bash-programmable-completion-tutorial
    # "${ps_name_list[*]}" expands into a single, space separated string, essentially just like $* 
    mapfile -t ps_name_list < <(ps -eo comm=)
    COMPREPLY=($(compgen -W "${ps_name_list[*]}" "${COMP_WORDS[1]}"))
}

pid-of () (
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 1 ]] && echo "Only one argument allowed." >&2 && return 2
    
    # awk part taken from here:
    #  https://unix.stackexchange.com/questions/102008/how-do-i-trim-leading-and-trailing-whitespace-from-each-line-of-some-output 
    ps ax -e -o pid,comm | grep "$1" | awk '{$1=$1;print}'
)

_venv-subshell_completions () {
    COMPREPLY=()
}

venv-subshell () {
    bash --init-file <(echo ". \"$HOME/.bashrc\"; . ./venv/bin/activate")
}

export -f bash-debug-subshell
export -f shellcheck-bash
complete -A file shellcheck-bash
export -f timeit
complete -A file timeit
export -f pid-of
complete -F _pid-of_completions pid-of
export -f venv-subshell
complete -F _venv-subshell_completions venv-subshell
