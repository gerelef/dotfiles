#!/usr/bin/env bash

if [[ -n "$__MATH_LOADED" ]]; then
    return 0
fi
readonly __MATH_LOADED="__LOADED"

# echo max out of N integers
max () (
    [[ -z "$*" ]] && return 2
    
    local m=0
    for i in "$@"; do
        [[ $i -gt $m ]] && local m="$i"
    done
    echo "$m"
)

# echo min out of N integers
min () (
    [[ -z "$*" ]] && return 2

    # bash uses 64 bit integers, this *should* be the maximum value for it
    local m=9223372036854775807
    for i in "$@"; do
        [[ $i -lt $m ]] && local m="$i"
    done
    echo "$m"
)

# checks if $1 is odd, echoes the mod result
is-odd () (
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 1 ]] && return 2
    
    echo "$(($1 % 2))"
)

# checks that $1 is factor of $2, returns 0 on success, and anything else returns !=
is-factor () (
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 2 ]] && return 2
    
    echo "$(($2 % $1))"
)

export -f max
export -f min
export -f is-odd
export -f is-factor
