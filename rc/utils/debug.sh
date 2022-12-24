#!/usr/bin/env bash

bash-debug-subshell () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 1 ]] && echo "Single quote your entire argument." >&2 && return 2
    
    bash --norc <(echo "set -euxo pipefail; $@; exit 0")
}

shellcheck-bash () {
    [[ -z "$*" ]] && return 2
    
    \shellcheck --enable='add-default-case|avoid-nullary-conditions|check-unassigned-uppercase|deprecate-which|quote-safe-variables|require-variable-braces' --format tty --color=always --check-sourced -x --shell bash "$@"
}
