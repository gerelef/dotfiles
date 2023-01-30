# AUTHOR NOTE:
#  Treat these tutorials like you would PEP8. Read in detail.
#   https://github.com/bahamas10/bash-style-guide#bashisms
#   https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md
#   https://tldp.org/HOWTO/Man-Page/q2.html 

DOTFILES_DIR="$HOME/dotfiles"
REQUIRE_DEPENDENCIES+="tldr openssl bat "

# EXPORTS
# https://unix.stackexchange.com/questions/90759/where-should-i-install-manual-pages-in-user-directory
export MANPATH="$MANPATH:$DOTFILES_DIR/man"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export HISTFILESIZE=100000
export HISTSIZE=10000
export HISTCONTROL=erasedups:ignoredups:ignorespace

#############################################################

require-packages-bashrc () {
    local HAS_RUN_FILE="$DOTFILES_DIR/.has-run"
    [[ -f $HAS_RUN_FILE ]] && return 0
    
    local DNF_MANAGER="$(which dnf 2> /dev/null)"
    local YUM_MANAGER="$(which yum 2> /dev/null)"
    local ZYP_MANAGER="$(which zypper 2> /dev/null)"
    local APT_MANAGER="$(which apt 2> /dev/null)"
    
    echo -e "Installing essential .bashrc packages: $_FRED"
    echo -n "$REQUIRE_DEPENDENCIES" | tr " " "\n"
    echo -ne "$_NOCOLOUR"
    if [[ -n "$DNF_MANAGER" ]]; then
        echo "using $DNF_MANAGER"
        sudo $DNF_MANAGER install -y $REQUIRE_DEPENDENCIES && touch $HAS_RUN_FILE
    elif [[ -n "$YUM_MANAGER" ]]; then
        echo "using $YUM_MANAGER"
        sudo $YUM_MANAGER install $REQUIRE_DEPENDENCIES && touch $HAS_RUN_FILE
    elif [[ -n "$ZYP_MANAGER" ]]; then
        echo "using $ZYP_MANAGER"
        sudo $ZYP_MANAGER install $REQUIRE_DEPENDENCIES && touch $HAS_RUN_FILE
    elif [[ -n "$APT_MANAGER" ]]; then
        echo "using $APT_MANAGER"
        sudo $APT_MANAGER install -y $REQUIRE_DEPENDENCIES && touch $HAS_RUN_FILE 
    fi
}

require-bashrc () {
    # Source global & private definitions
    local _GLOBAL_BASHRC="/etc/bashrc"
    local _PRIVATE_BASHRC="$HOME/.bashrc_private"

    local _UTILITY_DEBUG="$DOTFILES_DIR/rc/utils/debug.sh"
    local _UTILITY_FFMPEG="$DOTFILES_DIR/rc/utils/ffmpeg.sh"
    local _UTILITY_YTDL="$DOTFILES_DIR/rc/utils/ytdl.sh"
    local _UTILITY_MATH="$DOTFILES_DIR/rc/utils/math.sh"
    local _UTILITY_PROMPT="$DOTFILES_DIR/rc/utils/__setprompt.sh"
    
    [[ -f "$_GLOBAL_BASHRC" ]] && . "$_GLOBAL_BASHRC" 
    [[ -f "$_PRIVATE_BASHRC" ]] && . "$_PRIVATE_BASHRC"

    # SOFT DEPENDENCIES
    [[ -f "$_UTILITY_DEBUG" ]] && . "$_UTILITY_DEBUG"
    [[ -f "$_UTILITY_FFMPEG" ]] && . "$_UTILITY_FFMPEG"
    [[ -f "$_UTILITY_YTDL" ]] && . "$_UTILITY_YTDL"
    [[ -f "$_UTILITY_MATH" ]] && . "$_UTILITY_MATH"

    # HARD DEPENDENCIES
    [[ -f "$_UTILITY_PROMPT" ]] && . "$_UTILITY_PROMPT"
    
    # PACKAGE DEPENDENCIES
    require-packages-bashrc || return 1
}

# Get directory size 
gds () {
    if [[ -n "$*" ]]; then
        for arg in "$@"; do
            du -sh --apparent-size "$arg"
        done
    else
        du -sh --apparent-size .
    fi
}

# Highlight (and not filter) text with grep
highlight () {
    [[ -z "$*" ]] && return 2
    
    grep --color=always -iE "$1|\$"
}

# Rename
rn () {
    [[ -z "$*" ]] && return 2
    [[ $# -eq 2 ]] || return 2
    
    mv -vn "$1" "$2"
}

# call lss py implementation
lss () {
    $DOTFILES_DIR/rc/utils/lss.py "$@"
}

# Automatically do an ls after each cd
cd () { 
	builtin cd "$@" && lss
}

venv-subshell () {
    bash --init-file <(echo ". \"$HOME/.bashrc\"; . ./venv/bin/activate")
}

update-mono-ff-theme () {
    $DOTFILES_DIR/rc/utils/update-mono-ff-theme.py "$@"
}

# journalctl wrapper for ease of use
_journalctl () {
    [[ $# -eq 0 ]] && command journalctl -e -n 2000 && return
    # called with just a service name (-u)
    [[ $# -eq 1 ]] &&  command journalctl -e -n 5000 -u "$1" && return
    command journalctl "$@"
}

# tldr wrapper for ease of use
_tldr () {
    [[ $# -eq 0 ]] && (command tldr tldr) | less -R && return    
    [[ $# -eq 1 ]] && (command tldr "$1") | less -R && return
    command tldr "$@"
}

require-bashrc
PROMPT_COMMAND='__setprompt; history -a'

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
alias wget="\wget -c --read-timeout=5 --tries=0"
alias venv="venv-subshell" # activate venv
alias cvenv="python -m venv" # create venv (pythonXX cvenv)

alias restartpipewire="systemctl --user restart pipewire" # restart audio (pipewire)
alias restartnetworkmanager="systemctl restart NetworkManager" # restart internet (networkmanager)

alias reverse="tac"
alias palindrome="rev"

alias grep="\grep -i"
alias rm="rm -v"
alias ccat="bat --theme Dracula"
alias gedit="gnome-text-editor" # gedit replacement of choice
alias fuck='sudo $(history -p \!\!)'
