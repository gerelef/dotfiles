#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

if [[ -n "$__PROMPT_LOADED" ]]; then
    return 0
fi
readonly __PROMPT_LOADED="__LOADED"

DIR=$(dirname -- "$BASH_SOURCE")

# https://www.ditig.com/256-colors-cheat-sheet
readonly __BLACK="0m"
readonly __WHITE="15m"
readonly __BLUE="27m"
readonly __TURQUOISE="30m"
readonly __GREEN="34m"
readonly __CYAN="36m"
readonly __LIGHT_BLUE="39m"
readonly __PALE_GREEN="42m"
readonly __STEEL_BLUE="39m"
readonly __PURPLE="93m"
readonly __RED="124m"
readonly __MAGENTA="127m"
readonly __BROWN="138m"
readonly __LIGHT_MAGENTA="163m"
readonly __DARK_ORANGE="166m"
readonly __ORANGE="172m"
readonly __YELLOW="178m"
readonly __LIGHT_RED="196m"

readonly __PREFIX="\033["
readonly __FOREGROUND="38;"
readonly __BACKGROUND="48;"
readonly __INFIX="5;" # https://man7.org/linux/man-pages/man4/console_codes.4.html
readonly __PFI="$__PREFIX$__FOREGROUND$__INFIX"
readonly __PBI="$__PREFIX$__BACKGROUND$__INFIX"

readonly _NOCOLOUR="\033[0m"
readonly _BOLD="\033[1m"
readonly _UNDERLINE="\033[4m"
readonly _BLINK="\033[5m"
readonly _FSTEEL="$__PFI$__STEEL"
readonly _BSTEEL="$__PBI$__STEEL"
readonly _FBLUE="$__PFI$__BLUE"
readonly _BBLUE="$__PBI$__BLUE"
readonly _FCYAN="$__PFI$__CYAN"
readonly _BCYAN="$__PBI$__CYAN"
readonly _FTURQUOISE="$__PFI$__TURQUOISE"
readonly _BTURQUOISE="$__PBI$__TURQUOISE"
readonly _FLBLUE="$__PFI$__LIGHT_BLUE"
readonly _BLBLUE="$__PBI$__LIGHT_BLUE"
readonly _FGREEN="$__PFI$__GREEN"
readonly _BGREEN="$__PBI$__GREEN"
readonly _FPGREEN="$__PFI$__PALE_GREEN"
readonly _BPGREEN="$__PBI$__PALE_GREEN"
readonly _FMAGENTA="$__PFI$__MAGENTA"
readonly _BMAGENTA="$__PBI$__MAGENTA"
readonly _FLMAGENTA="$__PFI$__LIGHT_MAGENTA"
readonly _BLMAGENTA="$__PBI$__LIGHT_MAGENTA"
readonly _FYELLOW="$__PFI$__YELLOW"
readonly _BYELLOW="$__PBI$__YELLOW"
readonly _FRED="$__PFI$__RED"
readonly _BRED="$__PBI$__RED"
readonly _FLRED="$__PFI$__LIGHT_RED"
readonly _BLRED="$__PBI$__LIGHT_RED"
readonly _FBROWN="$__PFI$__BROWN"
readonly _BBROWN="$__PBI$__BROWN"
readonly _FPURPLE="$__PFI$__PURPLE"
readonly _BPURPLE="$__PBI$__PURPLE"
readonly _FORANGE="$__PFI$__ORANGE"
readonly _BORANGE="$__PBI$__ORANGE"
readonly _FDORANGE="$__PFI$__DARK_ORANGE"
readonly _BDORANGE="$__PBI$__DARK_ORANGE"
readonly _FWHITE="$__PFI$__WHITE"
readonly _BWHITE="$__PBI$__WHITE"
readonly _FBLACK="$__PFI$__BLACK"
readonly _BBLACK="$__PBI$__BLACK"

echo-colour-codes-256 () (
    # https://betterprogramming.pub/25-awesome-linux-command-one-liners-9495f26f07fb
    for code in {0..255}; do 
        echo -e "\e[38;05;${code}m $code: Test"
    done
)

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
