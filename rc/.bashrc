# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

#################### zachbrowne ##########################
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c
# Source global definitions
if [ -f /etc/bashrc ]; then
	 . /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

#######################################################
# EXPORTS
#######################################################

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=5000

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# Allow ctrl-S for history navigation (with ctrl-R)
stty -ixon

# Ignore case on auto-completion
# Note: bind used instead of sticking these in .inputrc
if [[ $iatest > 0 ]]; then bind "set completion-ignore-case on"; fi

# Show auto-completion list automatically, without double tab
if [[ $iatest > 0 ]]; then bind "set show-all-if-ambiguous on"; fi


# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
#export GREP_OPTIONS='--color=auto' #deprecated
alias grep="/usr/bin/grep $GREP_OPTIONS"
unset GREP_OPTIONS

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#######################################################
# GENERAL ALIAS'S
#######################################################
# To temporarily bypass an alias, we preceed the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls

# Alias's to modified commands
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -iv'
alias mkdir='mkdir -p'
alias ps='ps auxf'
alias less='less -R'

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# cd into the old directory
alias bd='cd "$OLDPWD"'

# Alias's for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# Alias's to show disk space and space used in a folder
alias tree='tree -CAhF --dirsfirst'

# archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# encryptions
alias md5="openssl md5"
alias sha1="openssl sha1"
alias sha256="openssl sha256"
alias sha512="openssl sha512"

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Searches for text in all files in the current folder
ftext () {
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

# Create and go to the directory
mkdirg () {
	mkdir -p $1
	cd $1
}

# Returns the last 2 fields of the working directory
pwdtail () {
	pwd|awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# For some reason, rot13 pops up everywhere
rot13 () {
	if [ $# -eq 0 ]; then
		tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
	else
		echo $* | tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
	fi
}

ffextract_audio () {
    ffmpeg -i "$1" -vn "$1.mp3"
}

fftrim_mp3 () {
    ffmpeg -ss "$2" -t "$3" -i "$1" -acodec copy "$1-trimmed.mp3" 
}

fftrim_mp4 () {
    ffmpeg -ss "$2" -to "$3" -i "$1" -codec copy "$1-trimmed.mp4"
}

ffcompress_mp3 () {
    ffmpeg -i "$1" -map 0:a:0 -b:a "$2" "$1-compressed.mp3"
}

ffcompress_mp4 () {
    ffmpeg -i "$1" -vcodec libx265 -crf "$2" "$1-compressed.mp4"
}

ytdl_mp3 () {
    yt-dlp --extract-audio --audio-format mp3 --audio-quality 0 "$@" 
}

ytdl_mp4 () {
    yt-dlp --format "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" "$@"
}

gbi () {
    if [ -n "$1" ] && [ -f "$1" ]; then
        echo "All instances of $1:"
        whereis "$1"
        echo ""
        echo "File & Filesystem information:"
        stat "$1"
        echo ""
        echo "Dependencies:"
        ldd "$1"
        echo ""
        echo "Technical information:"
        file "$1"
        echo ""
        readelf -h "$1"
        echo ""
        nm "$1" | head
    else
        if [ -n "$1" ]; then
            echo "File "$1" does not exist."
        else
            echo "usage: gbi path/to/bin"
        fi
    fi
}

# Multi-column ls
lss () {
    if [ -z "$1" ]; then
        ls_dir="$PWD"
    else
        ls_dir="$1"
    fi
    current_directory_dirs_out=$(ls -ap $1 | grep /; )
    current_directory_files_out=$(ls -ap $1 | grep -v /; )

    current_directory_status_out=""
    top_lvl_git_dir=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -n "$top_lvl_git_dir" ]; then
        current_directory_status_out=$(git status -s --ignored=no; )
        if [ "------ .git ------" == "$current_directory_status_out" ]; then
	        current_directory_status_out=$(echo "Your branch is up to date"; )
	    fi
	    paste <(echo "$current_directory_dirs_out") <(echo "$current_directory_files_out") <(echo "$current_directory_status_out") | column -o "│" -s $'\t' -t -d -N C1,C2,C3 -T C1,C2,C3
	    return
    fi
    paste <(echo "$current_directory_dirs_out") <(echo "$current_directory_files_out") | column -o "│" -s $'\t' -t -d -N C1,C2 -T C1,C2
}

# Highlight (and not filter) text with grep
highlight () {
    grep --color=always -E "$1|\$"
}

#Automatically do an ls after each cd
cd ()
{
	if [ -n "$1" ]; then
	    builtin cd "$@"
	else
		builtin cd $HOME
	fi
	if [ ! $? -eq 0 ]; then
	    return
	fi
	lss
}

# journalctl wrapper for ease of use
_journalctl () {
    # https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
    if [ $# -eq 0 ]; then
        command journalctl -e -n 2000
    elif [ $# -eq 1 ]; then # called with just a service name (-u opt)
        command journalctl -e -n 5000 -u "$1"
    else 
        command journalctl "$@"
    fi
}

# tldr wrapper for ease of use
_tldr () {
    if [ $# -eq 0 ]; then
        (command tldr tldr && command tldr --help) | less
    elif [ $# -eq 1 ]; then
        (command tldr "$1" && "$1" --help) | less
    else
        command tldr "$@"
    fi
}

_git_branch () {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

#######################################################
# Set the ultimate amazing command prompt
#######################################################
function __setprompt
{
	local LAST_COMMAND=$? # Must come first!

	# Define colors
	local LIGHTGRAY="\033[0;37m"
	local WHITE="\033[1;37m"
	local BLACK="\033[0;30m"
	local DARKGRAY="\033[1;30m"
	local RED="\033[0;31m"
	local LIGHTRED="\033[1;31m"
	local GREEN="\033[0;32m"
	local LIGHTGREEN="\033[1;32m"
	local BROWN="\033[0;33m"
	local YELLOW="\033[1;33m"
	local BLUE="\033[0;34m"
	local LIGHTBLUE="\033[1;34m"
	local MAGENTA="\033[0;35m"
	local LIGHTMAGENTA="\033[1;35m"
	local CYAN="\033[0;36m"
	local LIGHTCYAN="\033[1;36m"
	local NOCOLOR="\033[0m"
	
	PROMPT_DIRTRIM=2

	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		# PS1="\[${RED}\](\[${LIGHTRED}\]ERROR\[${RED}\])-(\[${LIGHTRED}\]Exit Code \[${WHITE}\]${LAST_COMMAND}\[${RED}\])-(\[${LIGHTRED}\]"
		# PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
		PS1="\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\] \[${RED}\]"
		if [[ $LAST_COMMAND == 1 ]]; then
			PS1+="General error"
		elif [ $LAST_COMMAND == 2 ]; then
			PS1+="Missing keyword, command, or permission problem"
		elif [ $LAST_COMMAND == 126 ]; then
			PS1+="Permission problem or command is not an executable"
		elif [ $LAST_COMMAND == 127 ]; then
			PS1+="Command not found"
		elif [ $LAST_COMMAND == 128 ]; then
			PS1+="Invalid argument to exit"
		elif [ $LAST_COMMAND == 129 ]; then
			PS1+="Fatal error signal 1"
		elif [ $LAST_COMMAND == 130 ]; then
			PS1+="Script terminated by Control-C"
		elif [ $LAST_COMMAND == 131 ]; then
			PS1+="Fatal error signal 3"
		elif [ $LAST_COMMAND == 132 ]; then
			PS1+="Fatal error signal 4"
		elif [ $LAST_COMMAND == 133 ]; then
			PS1+="Fatal error signal 5"
		elif [ $LAST_COMMAND == 134 ]; then
			PS1+="Fatal error signal 6"
		elif [ $LAST_COMMAND == 135 ]; then
			PS1+="Fatal error signal 7"
		elif [ $LAST_COMMAND == 136 ]; then
			PS1+="Fatal error signal 8"
		elif [ $LAST_COMMAND == 137 ]; then
			PS1+="Fatal error signal 9"
		elif [ $LAST_COMMAND -gt 255 ]; then
			PS1+="Exit status out of range"
		else
			PS1+="Unknown error code"
		fi
		PS1+="\n"
	else
		PS1=""
	fi
    
	# User and server
	local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
	local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
	if [ $SSH2_IP ] || [ $SSH_IP ] ; then
		PS1+="\[${RED}\]\u@\h"
	else
		PS1+="\[${RED}\]\u"
	fi
    
	# Current directory
	PS1+=" \[${BROWN}\]\w\[${DARKGRAY}\]"
    
    # active branch
    PS1+="\[${WHITE}\]$(_git_branch)"

	# Skip to the next line
	PS1+="\n"
    
    PS1+="\[${BLUE}\]\t\[${NOCOLOR}\] " # Time    
    
    if [ ! -z "$VIRTUAL_ENV" ] ; then
        DIRNAME="$VIRTUAL_ENV"
        D2=$(dirname "$DIRNAME")
        DIRNAME2=$(basename "$D2")/$(basename "$DIRNAME")
        
        PS1+="\[${LIGHTMAGENTA}\]$DIRNAME2\[${NOCOLOR}\] "
    fi
    
    PS1+="\[${GREEN}\]\$\[${NOCOLOR}\] " 
    
    
	# PS2 is used to continue a command using the \ character
	PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${DARKGRAY}\]+\[${NOCOLOR}\] "
}
PROMPT_COMMAND='__setprompt'

#################### zachbrowne ##########################

#################### USER STUFF ##########################
mkdir -p $HOME/bin/work/

export DOTNET_CLI_TELEMETRY_OPTOUT=1
PATH="$PATH:$HOME/Downloads/appImages"
PATH="$PATH:$HOME/bin/"

alias c="clear"
alias venv="source venv/bin/activate"
alias vvenv="deactivate"
alias cvenv="python -m venv venv"
alias restartpipewire="systemctl --user restart pipewire"
alias restartnetworkmanager="systemctl restart NetworkManager"
alias fuck='sudo $(history -p \!\!)'
alias journalctl="_journalctl"
alias help="_tldr"
alias ccat="bat"

# displays standard information every time shell starts
neofetch --off --color_blocks off --distro_shorthand tiny --gtk3 off --gtk2 off --gpu_type all --package_managers off --speed_type max --speed_shorthand on --cpu_brand off --cpu_cores logical --cpu_temp C --disable memory theme icons packages resolution
