#!/usr/bin/env bash

# echo max out of N integers
max () {
    local m=0
    for i in "$@"; do
        [[ $i -gt $m ]] && local m="$i"
    done
    echo $m
}

# echo min out of N integers
min () {
    # bash uses 64 bit integers, this *should* be the maximum value for it
    local m=9223372036854775807
    for i in "$@"; do
        [[ $i -lt $m ]] && local m="$i"
    done
    echo $m
}

export -f max
export -f min
