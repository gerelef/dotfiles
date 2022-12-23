#!/usr/bin/env bash

_git-branch () {
    if [[ ! -z "$1" ]]; then
        git -C "$1" branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
        return
    fi
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export -f _git-branch
