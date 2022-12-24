#!/usr/bin/env bash

# get current git branch in arg or current 
_git-branch () {
    # if superfluous arguments return...
    [[ $# -gt 1 ]] && return 2
    
    if [[ -n "$1" ]]; then
        git -C "$1" branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
        return
    fi
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export -f _git-branch
