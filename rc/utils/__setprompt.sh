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

function __setprompt
{
    local LAST_COMMAND=$? # Must come first!

    PROMPT_DIRTRIM=2
    PS1=""
    
    # Show error exit code if there is one
    if [[ $LAST_COMMAND != 0 ]]; then
        PS1+="\[${_FRED}\]Exit Code \[${_FLRED}\]${LAST_COMMAND}\[${_NOCOLOUR}\] \[${_FRED}\]"
        case $LAST_COMMAND in
            1) PS1+="General error";;
            2) PS1+="Missing keyword, command, or permission problem";;
            126) PS1+="Permission problem or command is not an executable";;
            127) PS1+="Possible problem with \$PATH or a typo";;
            128) PS1+="Invalid argument to exit" ;;
            129) PS1+="Fatal error signal SIGHUP";;
            130) PS1+="Script terminated by Control-C";;
            131) PS1+="Fatal error signal SIGQUIT";;
            132) PS1+="Fatal error signal SIGILL";;
            133) PS1+="Fatal error signal SIGTRAP";;
            134) PS1+="Fatal error signal SIGABRT";;
            135) PS1+="Fatal error signal SIGBUS";;
            136) PS1+="Fatal error signal SIGFPE";;
            137) PS1+="Fatal error signal SIGKILL";;
            139) PS1+="Fatal error signal SIGSEGV";;
            145) PS1+="Fatal error signal SIGSTERM";;
            *) PS1+="Unknown error code $LAST_COMMAND";;
        esac
        PS1+="\[${_NOCOLOUR}\]\n"
    fi
    
    PS1+="\[${_FLBLUE}\]\t\[${_NOCOLOUR}\]" # Time
    PS1+=" \[${_FYELLOW}\]\w\[${_NOCOLOUR}\]" # working directory
    PS1+="\[${_FORANGE}\]$(_git-branch 2> /dev/null)\[${_NOCOLOUR}\]" # active branch
    PS1+="\n"
    
    VENV_STATUS="${VIRTUAL_ENV:-N/A}"
    [[ "$VENV_STATUS" != "N/A" ]] && PS1+="\[${_FLMAGENTA}\]>>> \[${_NOCOLOUR}\]"
    [[ "$VENV_STATUS" == "N/A" ]] && PS1+="\[${_FGREEN}\]\$\[${_NOCOLOUR}\] "
    
    # PS2 is used to continue a command using the \ character
    PS2="\[${_FPGREEN}\]>\[${_NOCOLOUR}\] "

    # PS3 is used to enter a number choice in a script
    PS3='Please enter a number from above list: '

    # PS4 is used for tracing a script in debug mode
    PS4="\[${_FLRED}\]+\[${_NOCOLOUR}\] "
}

export -f __setprompt
