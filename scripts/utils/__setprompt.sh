#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

if [[ -n "$__PROMPT_LOADED" ]]; then
    return 0
fi
readonly __PROMPT_LOADED="__LOADED"

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/_git-branch.sh"
source "$DIR/colours.sh"

# this __setprompt is based on zachbrowne
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c

_get-err () (
    case $1 in
        1) echo "General error";;
        2) echo "Missing keyword, command, or permission problem";;
        126) echo "Permission problem or command is not an executable";;
        127) echo 'Possible problem with \$PATH or a typo';;
        128) echo "Invalid argument to exit" ;;
        129) echo "Fatal error signal SIGHUP";;
        130) echo "Script terminated by Control-C";;
        131) echo "Fatal error signal SIGQUIT";;
        132) echo "Fatal error signal SIGILL";;
        133) echo "Fatal error signal SIGTRAP";;
        134) echo "Fatal error signal SIGABRT";;
        135) echo "Fatal error signal SIGBUS";;
        136) echo "Fatal error signal SIGFPE";;
        137) echo "Fatal error signal SIGKILL";;
        139) echo "Fatal error signal SIGSEGV";;
        145) echo "Fatal error signal SIGSTERM";;
        *) echo "Unknown error code";;
    esac
)

og-prompt () {
    local LAST_COMMAND=$? # Must come first!

    PROMPT_DIRTRIM=2
    PS1=""

    # Show error exit code if there is one
    if [[ $LAST_COMMAND != 0 ]]; then
        PS1+="\[${_FRED}\]Exit Code \[${_FLRED}\]${LAST_COMMAND}\[${_NOCOLOUR}\] \[${_FRED}\]"
        PS1+=$(_get-err $LAST_COMMAND)
        PS1+="\[${_NOCOLOUR}\]\n"
    fi

    PS1+="\[${_FLBLUE}\]\t\[${_NOCOLOUR}\]" # Time
    PS1+=" \[${_FYELLOW}\]\w\[${_NOCOLOUR}\]" # working directory
    PS1+="\[${_FORANGE}\]$(_git-branch 2> /dev/null)\[${_NOCOLOUR}\] " # active branch
    PS1+="\[$_FBROWN\]$(_git-status 2> /dev/null)\[${_NOCOLOUR}\] " # staging status
    PS1+="\n"

    VENV_STATUS="${VIRTUAL_ENV:-N/A}"
    [[ "$VENV_STATUS" != "N/A" ]] && PS1+="\[${_FLMAGENTA}\]>>>\[${_NOCOLOUR}\] "
    [[ "$VENV_STATUS" == "N/A" ]] && PS1+="\[${_FGREEN}\]\$\[${_NOCOLOUR}\] "

    # PS2 is used to continue a command using the \ character
    PS2="\[${_FPGREEN}\]>\[${_NOCOLOUR}\] "

    # PS3 is used to enter a number choice in a script
    PS3='Please enter a number from above list: '

    # PS4 is used for tracing a script in debug mode
    PS4="\[${_FLRED}\]+\[${_NOCOLOUR}\] "
}

mini-prompt () {
    local LAST_COMMAND=$? # Must come first!
    PROMPT_DIRTRIM=1

    VENV_STATUS="${VIRTUAL_ENV:-N/A}"
    if [[ "$VENV_STATUS" != "N/A" ]]; then local PCOLOUR="$_FLMAGENTA"; local PHINT=">>>"; fi
    if [[ "$VENV_STATUS" == "N/A" ]]; then local PCOLOUR="$_FGREEN"; local PHINT="\$"; fi
    [[ -n "$(_git-branch 2> /dev/null)" ]] && PCOLOUR="$_FORANGE"

    PS1=" \[${_FYELLOW}\]\w\[${_NOCOLOUR}\] " # working directory
    [[ -n "$(_git-status 2> /dev/null)" ]] && PS1+="\[$_FBROWN\](changes)\[${_NOCOLOUR}\] "

    # Show error exit code if there is one
    [[ $LAST_COMMAND != 0 ]] && PS1+="\[${_FLRED}\][$LAST_COMMAND]\[${_NOCOLOUR}\] "

    PS1+="\[${PCOLOUR}\]$PHINT\[${_NOCOLOUR}\] "
    # PS2 is used to continue a command using the \ character
    PS2="\[${_FPGREEN}\]>\[${_NOCOLOUR}\] "
    # PS3 is used to enter a number choice in a script
    PS3='Please enter a number from above list: '
    # PS4 is used for tracing a script in debug mode
    PS4="+ "
}

export -f og-prompt
export -f mini-prompt
