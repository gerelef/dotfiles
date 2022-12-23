#!/usr/bin/env bash

# echo max out of N integers
max () {
    local m=0
    for i in "$@"; do
        [[ $i -gt $m ]] && local m="$i"
    done
    echo $m
}

export -f max
