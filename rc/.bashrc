# Source global definitions
_GLOBAL_BASHRC="/etc/bashrc"
_PRIVATE_BASHRC="$HOME/.bashrc_private"

DOTFILES_DIR="$HOME/dotfiles"
_UTILITY_FFMPEG="$DOTFILES_DIR/rc/utils/ffmpeg.sh"
_UTILITY_MAX="$DOTFILES_DIR/rc/utils/math.sh"
_UTILITY_GIT_BRANCH="$DOTFILES_DIR/rc/utils/_git-branch.sh"
_UTILITY_LSS="$DOTFILES_DIR/rc/utils/lss.sh"
_UTILITY_PROMPT="$DOTFILES_DIR/rc/utils/__setprompt.sh"


[[ -f "$_GLOBAL_BASHRC" ]] && . "$_GLOBAL_BASHRC" 
[[ -f "$_PRIVATE_BASHRC" ]] && . "$_PRIVATE_BASHRC"

# SOFT DEPENDENCIES
[[ -f "$_UTILITY_FFMPEG" ]]     && . "$_UTILITY_FFMPEG"
[[ -f "$_UTILITY_MAX" ]]        && . "$_UTILITY_MAX"

# HARD DEPENDENCIES
[[ -f "$_UTILITY_LSS" ]]        && . "$_UTILITY_LSS"
[[ -f "$_UTILITY_PROMPT" ]]     && . "$_UTILITY_PROMPT"

# EXPORTS
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export HISTFILESIZE=100000
export HISTSIZE=10000
export HISTCONTROL=erasedups:ignoredups:ignorespace

# AUTHOR NOTE:
#  Treat this tutorial like you would PEP8. Read in detail.
#   https://github.com/bahamas10/bash-style-guide#bashisms
shopt -s globstar

# SHOPT
shopt -s checkwinsize
shopt -s histappend

PROMPT_COMMAND='history -a'

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

PROMPT_COMMAND='__setprompt'
#############################################################

hexcat () {
    for arg in "$@"; do
        xxd < "$arg"
    done
}

# Get directory size 
gds () {
    if [[ -n "$1" ]]; then
        du -sh --apparent-size "$1"
    else
        du -sh --apparent-size .
    fi
}

# Highlight (and not filter) text with grep
highlight () {
    grep --color=always -iE "$1|\$"
}

# Rename
rn () {
    mv -vn "$1" "$2"
}

# Automatically do an ls after each cd
cd () {
	if [[ -n "$1" ]]; then
	    builtin cd "$@" || exit
	else
		builtin cd $HOME || exit
	fi
	lss
}

# journalctl wrapper for ease of use
_journalctl () {
    # https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
    if [[ $# -eq 0 ]]; then
        command journalctl -e -n 2000
    elif [[ $# -eq 1 ]]; then # called with just a service name (-u opt)
        command journalctl -e -n 5000 -u "$1"
    else
        command journalctl "$@"
    fi
}

# tldr wrapper for ease of use
_tldr () {
    if [[ $# -eq 0 ]]; then
        (command tldr tldr) | less -R
    elif [[ $# -eq 1 ]]; then
        (command tldr "$1") | less -R
    else
        command tldr "$@"
    fi
}

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

# encryptions
alias md5="openssl md5"
alias sha1="openssl sha1"
alias sha256="openssl sha256"
alias sha512="openssl sha512"

alias bd='cd "$OLDPWD"'
alias less='less -R'

# dir up
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# substitutes for commands
alias journalctl="_journalctl"
alias tldr="_tldr"
alias flatpak-log="flatpak remote-info --log flathub"
alias flatpak-checkout="flatpak update --commit="

# convenience alias
alias c="clear"
alias venv="source venv/bin/activate" # activate venv
alias vvenv="deactivate"        # exit venv
alias cvenv="-m venv venv" # create venv (pythonXX cvenv)

alias restartpipewire="systemctl --user restart pipewire" # restart audio (pipewire)
alias restartnetworkmanager="systemctl restart NetworkManager" # restart internet (networkmanager)

alias reverse="tac"
alias palindrome="rev"

alias grep="\grep -i"
alias rm="rm -v"
alias ccat="bat --theme Dracula"
alias gedit="gnome-text-editor" # gedit replacement of choice
alias fuck='sudo $(history -p \!\!)'
