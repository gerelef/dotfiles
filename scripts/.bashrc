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
# https://man7.org/linux/man-pages/man4/console_codes.4.html
# foreground prefix is "\033[38;5;"
readonly _NOCOLOUR="\033[0m"
readonly _BOLD="\033[1m"
readonly _UNDERLINE="\033[4m"
readonly _BLINK="\033[5m"
readonly _FLBLUE="\033[38;5;39m"
readonly _FGREEN="\033[38;5;34m"
readonly _FPGREEN="\033[38;5;42m"
readonly _FLMAGENTA="\033[38;5;163m"
readonly _FYELLOW="\033[38;5;178m"
readonly _FRED="\033[38;5;124m"
readonly _FLRED="\033[38;5;196m"
readonly _FBROWN="\033[38;5;138m"
readonly _FORANGE="\033[38;5;172m"
# background prefix is "\033[48;5;"

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

    return 0
    # echo "(changes)"
)

mini-prompt () {
    local LAST_COMMAND=$? # Must come first!
    PROMPT_DIRTRIM=1

    VENV_STATUS="${VIRTUAL_ENV:-N/A}"
    if [[ "$VENV_STATUS" != "N/A" ]]; then local PCOLOUR="$_FLMAGENTA"; local PHINT=">>>"; fi
    if [[ "$VENV_STATUS" == "N/A" ]]; then local PCOLOUR="$_FGREEN"; local PHINT="\$"; fi
    [[ -n "$(_git-branch "$(pwd)" 2> /dev/null)" ]] && PCOLOUR="$_FORANGE"

    PS1=" \[${_FYELLOW}\]\w\[${_NOCOLOUR}\] " # working directory
    [[ -n "$(_git-status "$(pwd)" 2> /dev/null)" ]] && PS1+="\[$_FBROWN\](changes)\[${_NOCOLOUR}\] "

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
            local venv_dir=\"$venv_dir/v$python_version_number\"

            # if venv dir doesn't exist for our version create it
            if [[ ! -d \"\$venv_dir\" ]]; then
                echo \"\$venv_dir doesn't exist; creating venv for $python_version\"

                # special case of the trick below: if python version < 3 (2.7 e.g.) use a special way for venv init
                if [[ ${python_version_number%.*} -lt 3 ]]; then
                    $python_version  -m ensurepip --user
                    $python_version -m pip install virtualenv --user
                    $python_version -m virtualenv --python=\"$python_version\" \"\$venv_dir\"
                    bash --init-file <(echo \"source \\\"$HOME/.bashrc\\\"; source \$venv_dir/bin/activate; pip install --upgrade setuptools wheel pip; exit\")
                else
                    $python_version -m venv \"\$venv_dir\" # for python >= 3
                    bash --init-file <(echo \"source \\\"$HOME/.bashrc\\\"; source \$venv_dir/bin/activate; pip install --upgrade setuptools wheel pip; exit\")
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
    activate_bash="$(find . -maxdepth 3 -name "activate" | head -n 1)"
    if [[ -f "$activate_bash" ]]; then
        bash --init-file <(echo "source \"$HOME/.bashrc\"; source $activate_bash")
        return
    fi
    return 1
}

#############################################################
# SOURCES

# add shell functions (executables) to $PATH
PATH=$PATH:$DOTFILES_DIR/scripts/functionz
# add user-local binaries to $PATH. WARNING: this can cause confusion
#  when installing software if it cannot be found; use `whereis` to clear things up.
PATH=$PATH:$HOME/bin
PATH=$PATH:$HOME/.local/bin
# source global virtual python install(s)
require-pip
# source cargo environment if it exists
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

_install-optional-shell-requirements () {
    # install optional shell requirements; the current .*rc config will work without them,
    #  but these are significant QOL upgrades over the regular terminal experience
    if [[ -z "$(command -v pkcon)" ]]; then
        echo "Cannot invoke 'pkcon' (part of PackageKit), packages CANNOT be installed! " 1>&2
        return 1
    fi
    # zoxide is used as a reference point for echoing out a helpful tip on startup, see below
    pkcon install --allow-reinstall zoxide lsd plocate
}

# use custom prompt
PROMPT_COMMAND='mini-prompt; history -a'
[[ -n "$(command -v _install-required-functionz-requirements)" ]] && functionz_postfix="\n Invoke '_install-required-functionz-requirements' to install dotfile's functionz dependencies."
[[ -n "$(command -v zoxide)" ]] || echo -e "Welcome to ba/sh! Invoke '_install-optional-shell-requirements' to install QoL enhancements.$functionz_postfix"

#############################################################
# ALIAS

# dir up
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# convenience alias
alias egrep="\grep -E"
alias grep="\grep -i"
alias rm="\rm -v"
alias reverse="\tac"
alias palindrome="\rev"
# vpip is defined above as a function
alias fuck='sudo $(history -p \!\!)'

[[ -n "$(command -v wget)" ]] && alias wget="\wget -c --read-timeout=5 --tries=0 --cut-file-get-vars --content-disposition"
[[ -n "$(command -v npm)" ]] && alias npm="\npm --loglevel silly"

# chromium depot_tools, add to PATH only if they actually exist
#  https://chromium.googlesource.com/chromium/tools/depot_tools.git
# `locate --version` checks if it exists, and is a 'mac' style locate or not
if locate --version 2> /dev/null 1>&2 && locate --limit 1 'depot_tools' 2> /dev/null 1>&2; then
    # add shell functions (executables) to $PATH
    PATH=$PATH:"$(locate --limit 1 depot_tools)"
    alias fetch="\fetch --no-history"
fi

if [[ -n "$(command -v vi)" ]]; then
    export VISUAL="vi"
    export EDITOR="vi"
fi

if [[ -n "$(command -v vim)" ]]; then
    export VISUAL="vim"
    export EDITOR="vim"
fi

if [[ -n "$(command -v nvim)" ]]; then
    export VISUAL="nvim"
    export EDITOR="nvim"
fi

if [[ -n "$(command -v hx)" ]]; then
    export VISUAL="hx"
    export EDITOR="hx"
fi

if [[ -n "$(command -v zoxide)" ]]; then
    cd () {
        z "$@"
    }
    eval "$(zoxide init bash)"
fi

if [[ -n "$(command -v lsd)" ]]; then
    alias lss="lsd -A --group-dirs=first --blocks=permission,user,group,date,name --date '+%d/%m %H:%M:%S'"
fi

if locate --version 2> /dev/null 1>&2 && test -n "$(command -v fzf)"; then
    __fzflocate () {
        local WITH_LOCAL_DB=""
        if test -f ~/.locate.db; then
            WITH_LOCAL_DB="-d $HOME/.locate.db"
        fi
        # we want this to expand to 'locate' parameters
        locate $WITH_LOCAL_DB -i "$1" | fzf
    }

    __updatedb_local () {
        updatedb --require-visibility 0 -o ~/.locate.db
    }

    alias locate="__fzflocate"
    alias updatedb="__updatedb_local"
fi
