# exit for non-interactive shells
[[ -z "$PS1" ]] && return

# AUTHOR NOTE:
#  Treat these tutorials like you would PEP8. Read in detail.
#   https://github.com/bahamas10/bash-style-guide#bashisms
#   https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md
#   https://tldp.org/HOWTO/Man-Page/q2.html

#############################################################
# GLOBAL CONSTANTS & EXPORTS
readonly DOTFILES_DIR="$HOME/dotfiles"

export DOTNET_CLI_TELEMETRY_OPTOUT=1

export HISTFILESIZE=100000
export HISTSIZE=10000
export HISTCONTROL=erasedups:ignoredups:ignorespace

#############################################################
# OPTIONS

shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize
shopt -s histappend

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

#############################################################
# PROMPT

# https://www.ditig.com/256-colors-cheat-sheet
readonly __GREEN="34m"
readonly __LIGHT_BLUE="39m"
readonly __PALE_GREEN="42m"
readonly __RED="124m"
readonly __BROWN="138m"
readonly __LIGHT_MAGENTA="163m"
readonly __ORANGE="172m"
readonly __YELLOW="178m"
readonly __LIGHT_RED="196m"

readonly __PREFIX="\033["
readonly __FOREGROUND="38;"
readonly __BACKGROUND="48;"
# https://man7.org/linux/man-pages/man4/console_codes.4.html
readonly __INFIX="5;" 
readonly __PFI="$__PREFIX$__FOREGROUND$__INFIX"
readonly __PBI="$__PREFIX$__BACKGROUND$__INFIX"

readonly _NOCOLOUR="\033[0m"
readonly _BOLD="\033[1m"
readonly _UNDERLINE="\033[4m"
readonly _BLINK="\033[5m"
readonly _FLBLUE="$__PFI$__LIGHT_BLUE"
readonly _FGREEN="$__PFI$__GREEN"
readonly _FPGREEN="$__PFI$__PALE_GREEN"
readonly _FLMAGENTA="$__PFI$__LIGHT_MAGENTA"
readonly _FYELLOW="$__PFI$__YELLOW"
readonly _FRED="$__PFI$__RED"
readonly _FLRED="$__PFI$__LIGHT_RED"
readonly _FBROWN="$__PFI$__BROWN"
readonly _FORANGE="$__PFI$__ORANGE"

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

#############################################################
# PYTHON VENV(s)

# goal: we want to create alot of different vpipN () (...) functions to call
#  for every different virtual environment that we have; e.g. python3.11 will have vpip3.11
#  which calls for the activation of the virtual environment of python3.11 stored somewhere on the system
#  to do that, we're going to (1) create a mock file (2) dump all these different functions in it
#  (3) source it (4) then promptly delete it so we don't create garbage files & for (perhaps) obscure security reasons
#    these functions (which only differ by the python version they're calling) should:
#      (1) check if a venv (for this specific version) exists in the venv directory. If it doesn't, 
#        (1a) create a new venv for this specific version
#      (2) source the activation script (and enter the venv)

# important note: the statement pythonX.x -m venv \"\$venv_dir\" won't work with 2.7 or lower,
#  for that, we need the virtualenv module
prepare-pip () (
    readonly vpip_fname="/tmp/vpip-temp-$(date +%s%N).sh"
    readonly venv_dir="$HOME/.vpip"
    local python_versions=()

    # get all the appropriate versions from the filesystem
    # https://stackoverflow.com/a/57485303
    for pv in "$(ls -1 /usr/bin/python* | grep '.*[0-9]\.\([0-9]\+\)\?$' | sort --version-sort)"; do
        python_versions+=("$pv")
    done

    # create mock functions
    for python_version in $python_versions; do
        # sanitize the filename and keep only the numbers at the end
        python_version_number="$(echo $python_version | tr -d -c 0-9.)"

        virtual_group_subshell="vpip$python_version_number () {
            [[ \"\$EUID\" -eq 0 ]] && echo \"Do NOT run as root.\" && return 2; 
            [[ ! -d \"$venv_dir\" ]] && mkdir -p \"$venv_dir\" # create root dir if doesn't exist
            local venv_dir=\"$venv_dir/dvpip$python_version_number\"

            # if venv dir doesn't exist for our version create it
            if [[ ! -d \"\$venv_dir\" ]]; then
                echo \"\$venv_dir doesn't exist; creating venv for $python_version\"

                # special case of the trick below: if python version < 3 (2.7 e.g.) use a special way for venv init
                if [[ ${python_version_number%.*} -lt 3 ]]; then
                    $python_version  -m ensurepip --user
                    $python_version -m pip install virtualenv --user
                    $python_version -m virtualenv --python=\"$python_version\" \"\$venv_dir\"
                else
                    $python_version -m venv \"\$venv_dir\" # for python >= 3
                fi
            fi

            bash --init-file <(echo \"source \\\"$HOME/.bashrc\\\"; source \$venv_dir/bin/activate\")
        }"

        # append to the file
        echo "$virtual_group_subshell" >> $vpip_fname
    done

    echo $vpip_fname
)

require-pip () {
    local vpip_fname="$(prepare-pip)"

    # source the file & delete
    source "$vpip_fname"
    rm "$vpip_fname"
}

vpip () {
    readonly activate_bash="$(find . -name "activate" | head -n 1)"
    if [[ -f "$activate_bash" ]]; then
        bash --init-file <(echo "source \"$HOME/.bashrc\"; source $activate_bash")
        return
    fi
    return 1
}

#############################################################
# SOURCES

# add shell functions (executables) to $PATH
PATH=$PATH:$DOTFILES_DIR/scripts/functions

# install required login shell packages
require-login-shell-packages
# source global virtual python install(s)
require-pip
# source cargo environment if it exists
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# use custom prompt
PROMPT_COMMAND='mini-prompt; history -a'

#############################################################
# ALIAS

# dir up
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# convenience alias
alias lss="lsd --almost-all --icon never --icon-theme unicode --group-directories-first"
alias wget="\wget -c --read-timeout=5 --tries=0"
alias grep="\grep -i"
alias rm="rm -v"
alias reverse="tac"
alias palindrome="rev"

alias fuck='sudo $(history -p \!\!)'
