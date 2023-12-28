#!/usr/bin/env bash

if [[ -n "$__GIT_BRANCH_LOADED" ]]; then
    return 0
fi
readonly __GIT_BRANCH_LOADED="__LOADED"
REQUIRE_DEPENDENCIES+="git "

# get current git branch in arg or current 
_git-branch () (
    # if superfluous arguments return to prevent misuse
    [[ $# -gt 1 ]] && return 2
    
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
)

_git-status () (
    # path MUST be given
    [[ $# -gt 1 ]] && return 2
    
    changed_files=$(git status -s --ignored=no 2> /dev/null)
    [[ -z $changed_files ]] && return
    
    echo "(changes pending)"
)

export -f _git-branch
complete -A directory _git-branch
export -f _git-status
complete -A directory _git-status
