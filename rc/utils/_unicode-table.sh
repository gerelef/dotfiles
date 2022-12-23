#!/usr/bin/env bash

_unicode_table () {
    [[ -z "$@" ]] && return
    local START_SYMBOL="┌"
    local JOIN_SYMBOL="┬"
    local ROW_SYMBOL="─"
    local END_SYMBOL="┐"
    if [[ "$1" == "--bot" ]]; then
        local START_SYMBOL="└"
        local JOIN_SYMBOL="┴"
        local ROW_SYMBOL="─"
        local END_SYMBOL="┘"
    fi
    
    local sizes=()
    
    for arg in "${@:2}"; do
        local sizes+=( "$arg" )
    done
    
    local cc=1
    echo -n "$START_SYMBOL"
    for s in "${sizes[@]}"; do
        for ((i=0; i<$s; ++i)); do
            echo -n "$ROW_SYMBOL"
        done
        
        [[ $cc -lt "${#sizes[@]}" ]] && echo -n "$JOIN_SYMBOL"
        ((++cc))
    done
    echo "$END_SYMBOL"
}

export -f _unicode_table
