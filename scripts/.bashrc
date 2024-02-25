# exit for non-interactive shells
[[ -z "$PS1" ]] && return

# AUTHOR NOTE:
#  Treat these tutorials like you would PEP8. Read in detail.
#   https://github.com/bahamas10/bash-style-guide#bashisms
#   https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md
#   https://tldp.org/HOWTO/Man-Page/q2.html

# git-delta are required for the current .gitconfig
REQUIRE_DEPENDENCIES+="bat lsd git-delta"

#############################################################

# GLOBAL CONSTANTS
readonly DOTFILES_DIR="$HOME/dotfiles"
readonly HAS_RUN_FILE="$DOTFILES_DIR/.has-run"
readonly HAS_RUN_ZSH_FILE="$DOTFILES_DIR/.has-run-zsh"
readonly HAS_RUN_FSH_FILE="$DOTFILES_DIR/.has-run-fsh"
readonly HAS_RUN_KSH_FILE="$DOTFILES_DIR/.has-run-ksh"

# EXPORTS
# https://unix.stackexchange.com/questions/90759/where-should-i-install-manual-pages-in-user-directory
export MANPATH="$MANPATH:$DOTFILES_DIR/.manpages"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export HISTFILESIZE=100000
export HISTSIZE=10000
export HISTCONTROL=erasedups:ignoredups:ignorespace
#############################################################
# package management

install-system-pkg () (
    while :; do
        [[ -n "$(command -v dnf)" ]] && sudo dnf install -y "$@" && break
        [[ -n "$(command -v yum)" ]] && sudo yum install -y "$@" && break
        [[ -n "$(command -v apt)" ]] && sudo apt install -y "$@" && break
        break
    done
)

update-everything () (
    # the reason this for loop exists is to act as a "block", so we can break control flow
    #  when we're done updating platform packages (since there will be only 1 package manager per sys)
    while :; do
        [[ -n "$(command -v dnf)" ]] && (sudo dnf upgrade -y --refresh && sudo dnf autoremove -y) && break
        [[ -n "$(command -v pacman)" ]] && sudo pacman -Syu && break
        [[ -n "$(command -v yum)" ]] && sudo yum update -y && break
        [[ -n "$(command -v apt)" ]] && (sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y) && break
        break
    done
    [[ -n "$(command -v flatpak)" ]] && (flatpak update -y && flatpak uninstall --unused -y && sudo flatpak repair)
    [[ -n "$(command -v snap)" ]] && snap refresh -y

    [[ -n "$(command -v updatedb)" ]] && sudo updatedb
    [[ -n "$(command -v update-grub)" ]] && sudo update-grub
    return 0
)

require-bashrc-packages () (
    [[ -f $HAS_RUN_FILE ]] && return 0

    echo -e "Installing essential .bashrc packages: $_FGREEN"
    echo -n "$REQUIRE_DEPENDENCIES" | tr " " "\n"
    echo -ne "$_NOCOLOUR"

    install-system-pkg $REQUIRE_DEPENDENCIES && touch $HAS_RUN_FILE && clear
)

require-bashrc () {
    # Source global & private definitions
    local _GLOBAL_BASHRC="/etc/bashrc"
    local _PRIVATE_BASHRC="$HOME/.bashrc-private"

    local _UTILITY_DEBUG="$DOTFILES_DIR/scripts/utils/debug.sh"
    local _UTILITY_FFMPEG="$DOTFILES_DIR/scripts/utils/ffmpeg.sh"
    local _UTILITY_YTDL="$DOTFILES_DIR/scripts/utils/ytdl.sh"
    local _UTILITY_MATH="$DOTFILES_DIR/scripts/utils/math.sh"
    local _UTILITY_PROMPT="$DOTFILES_DIR/scripts/utils/__setprompt.sh"

    [[ -f "$_GLOBAL_BASHRC" ]] && source "$_GLOBAL_BASHRC"
    [[ -f "$_PRIVATE_BASHRC" ]] && source "$_PRIVATE_BASHRC"

    # SOFT DEPENDENCIES
    [[ -f "$_UTILITY_DEBUG" ]] && source "$_UTILITY_DEBUG"
    [[ -f "$_UTILITY_FFMPEG" ]] && source "$_UTILITY_FFMPEG"
    [[ -f "$_UTILITY_YTDL" ]] && source "$_UTILITY_YTDL"
    [[ -f "$_UTILITY_MATH" ]] && source "$_UTILITY_MATH"
    [[ -f "~/.cargo/env" ]] && source "~/.cargo/env"

    # HARD DEPENDENCIES
    [[ -f "$_UTILITY_PROMPT" ]] && source "$_UTILITY_PROMPT"

    # PACKAGE DEPENDENCIES
    require-bashrc-packages || return 1
}

dnf-installed-packages-by-size () (
    # https://forums.fedoraforum.org/showthread.php?314323-Useful-one-liners-feel-free-to-update&p=1787643
    dnf -q --disablerepo=* info installed | sed -n 's/^Name[[:space:]]*: \|^Size[[:space:]]*: //p' | sed 'N;s/\n/ /;s/ \(.\)$/\1/' | sort -hr -k 2 | less
)

_dnf-installed-packages-by-size_completions () {
    COMPREPLY=()
}

complete -F _dnf-installed-packages-by-size_completions dnf-installed-packages-by-size

#############################################################
# pure bash helpers
# Get directory size
gds () (
    if [[ -n "$*" ]]; then
        for arg in "$@"; do
            du -sh --apparent-size "$arg"
        done
    else
        du -sh --apparent-size .
    fi
)

complete -A directory gds

watch-dir () (
    [[ $# -ne 1 ]] && return 2

    watch -n 1 "lsof +D $1"
)

# Highlight (and not filter) text with grep
highlight () (
    [[ -z "$*" ]] && return 2

    grep --color=always -iE "$1|\$"
)

# Rename
rn () (
    [[ -z "$*" ]] && return 2
    [[ $# -eq 2 ]] || return 2

    mv -vn "$1" "$2"
)

restart-pipewire () (
    systemctl --user restart pipewire
)

_restart-pipewire_completions () {
    COMPREPLY=()
}

complete -F _restart-pipewire_completions restart-pipewire

restart-network-manager () (
    systemctl restart NetworkManager
)

_restart-network-manager_completions () {
    COMPREPLY=()
}

complete -F _restart-network-manager_completions restart-network-manager

#############################################################
# PYTHON SCRIPTS

update-ff-theme () (
    # for future reference: curl -fsSL https:// | bash -s -- - "~/dotfiles/.config/mozilla/userChrome.css" "$@"
    $DOTFILES_DIR/scripts/utils/update-ff-theme.py --resource ~/dotfiles/.config/mozilla/userChrome.css "$@"
)

update-compat-layers () (
    # curl -fsSL https:// | bash -s -- - "$@"
    return 1
)

pstow () (
    # curl --tlsv1.2 -fsSL https://my/url.py | python -- -
    "$DOTFILES_DIR/scripts/utils/pstow.py" "$@"
)

#############################################################
# WRAPPERS TO BUILTINS OR PATH EXECUTABLES

# journalctl wrapper for ease of use
_journalctl () (
    [[ $# -eq 0 ]] && command journalctl -e -n 2000 && return
    # called with just a service name (-u)
    [[ $# -eq 1 ]] &&  command journalctl -e -n 5000 -u "$1" && return
    command journalctl "$@"
)

lss () (
    lsd --almost-all --icon never --icon-theme unicode --group-directories-first "$@"
)

complete -A directory lss

alias journalctl="_journalctl"
complete -A service journalctl

# Automatically do an ls after each cd
cd () {
	builtin cd "$@" && lss
}

#############################################################
# DIFFERENT SHELLS

require-ksh-packages () (
    [[ -f $HAS_RUN_KSH_FILE ]] && return 0

    echo -ne "$_FBROWN"
    echo -e "Installing ksh $_NOCOLOUR"

    install-system-pkg ksh && touch $HAS_RUN_KSH_FILE && clear
)

ksh () (
    require-ksh-packages

    /usr/bin/env ksh
)

require-fsh-packages () (
    [[ -f $HAS_RUN_FSH_FILE ]] && return 0

    echo -ne "$_FBLUE"
    echo -e "Installing fish $_NOCOLOUR"

    install-system-pkg fish && touch $HAS_RUN_FSH_FILE && clear
)

fsh () (
    require-fsh-packages

    /usr/bin/env fish
)

require-zsh-packages () (
    [[ -f $HAS_RUN_ZSH_FILE ]] && return 0

    echo -ne "$_FYELLOW"
    echo -e "Installing zsh $_NOCOLOUR"

    install-system-pkg zsh && touch $HAS_RUN_ZSH_FILE && clear
)

zsh () (
    require-zsh-packages

    /usr/bin/env zsh
)

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

require-pip

#############################################################
# BASH OPTIONS

require-bashrc
PROMPT_COMMAND='mini-prompt; history -a'

shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize
shopt -s histappend

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

#############################################################

alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'
alias unxz="tar -xf"

alias bd='cd "$OLDPWD"'
alias less='less -R'

# dir up
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# substitutes for commands
alias flatpak-log="flatpak remote-info --log flathub"
alias flatpak-checkout="flatpak update --commit="

# convenience alias
alias c="clear"
alias wget="\wget -c --read-timeout=5 --tries=0"
alias mkvenv="python -m venv venv" # create venv (pythonXX cvenv)

alias reverse="tac"
alias palindrome="rev"

alias grep="\grep -i"
alias rm="rm -v"
alias gedit="gnome-text-editor" # gedit replacement of choice
alias fuck='sudo $(history -p \!\!)'
