#!/usr/bin/env bash

if [[ -n "$__GIT_BRANCH_LOADED" ]]; then
    return 0
fi
readonly __GIT_BRANCH_LOADED="__LOADED"

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
