# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# ~/.bashrc: executed by bash(1) for non-login shells.

# AUTHOR NOTE:
#  Treat this like you would PEP8 for Python. Read in detail.
#   https://github.com/bahamas10/bash-style-guide#bashisms

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
if [[ -d ~/.bashrc.d ]]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

export DOTNET_CLI_TELEMETRY_OPTOUT=1

#################### zachbrowne ##########################
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c
# Source global definitions
if [[ -f /etc/bashrc ]]; then
	 . /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
	. /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
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
alias grep="/usr/bin/grep -i $GREP_OPTIONS"
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

# convert Hours:Minutes:Seconds (colon seperated) to seconds 
hms () {
    echo "$1" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }';
}

# ffmpeg concatenate multiple video files into one 
#  INPUTS: files >= 2
ffconcat-video () {
    local inputs=""
    local audio_video_ftracks=""
    local trimmed_arg=""
    local output_name=""
    local count=0
    for arg in "$@"; do
        inputs+="-i $arg "
        audio_video_ftracks+="[$count:v] [$count:a] "
        trimmed_arg=${arg%.*}
        output_name+=$(head -c 4 <<< $trimmed_arg)
        count=$((count+1))
    done
    local output_name=$(head -c 30 <<< $output_name)
    local output_name+="-concat$count.mp4"
    ffmpeg $inputs -filter_complex "$audio_video_ftracks concat=n=$count:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" -vsync 1 -r 60 "$output_name" 
}

# ffmpeg convert audio file to mp3
ffconvert-mp3 () {
    local output=${1%.*}
    ffmpeg -i "$1" -acodec libmp3lame "$output-converted.mp3"
}

# ffmpeg convert video file to mp4
ffconvert-mp4 () {
    local output=${1%.*}
    ffmpeg -i "$1" -codec copy "$output-converted.mp4"
}

# ffmpeg extract audio from video with audio to mp3
ffextract-audio-mp3 () {
    local output=${1%.*}
    ffmpeg -i "$1" -vn "$output-audio.mp3"
}

# ffmpeg extract video from video with audio to mp3
ffextract-video-mp4 () {
    local output=${1%.*}
    ffmpeg -i "$1" -c copy -an "$output-video.mp4"
}

# ffmpeg scale video file to selected resolution 
ffscale-mp4 () {
    # $1 input
    # $2 width:height
    local output=${1%.*}
    ffmpeg -i "$1" -vf scale="$2" -vcodec libx265 -crf 22 -vsync 1 -r 60 "$output-scaled.mp4"
}

# ffmpeg trim mp3 from start to end
fftrim-mp3 () {
    # $1 input
    # $2 start (seconds)
    # $3 duration (seconds)
    local output=${1%.*}
    ffmpeg -ss "$2" -t "$3" -i "$1" -acodec copy "$output-trimmed.mp3" 
}

# ffmpeg trim mp4 from start to end
fftrim-mp4 () {
    # $1 input
    # $2 start (seconds)
    # $3 end   (seconds)
    local output=${1%.*}
    ffmpeg -ss "$2" -to "$3" -i "$1" -codec copy "$output-trimmed.mp4"
}

# ffmpeg compress mp3 audio
ffcompress-mp3 () {
    # $1 input
    # $2 bitrate (e.g. 96k)
    local output=${1%.*}
    ffmpeg -i "$1" -map 0:a:0 -b:a "$2" "$output-compressed.mp3"
}

# ffmpeg compress mp4 video
ffcompress-mp4 () {
    # $1 input
    # $2 crf logarithmic value for x265
    #  good values are from 27 to 30
    local output=${1%.*}
    ffmpeg -i "$1" -vcodec libx265 -crf "$2" -vsync 1 -r 60 "$output-compressed.mp4"
}

# yt-dlp download to mp3
ytdl-mp3 () {
    yt-dlp --extract-audio --audio-format mp3 --audio-quality 0 "$@" 
}

# yt-dlp download to mp4
ytdl-mp4 () {
    yt-dlp --format "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" "$@"
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

# Multi-column ls
lss () {
    if [[ -z "$1" ]]; then
        local ls_dir="$PWD"
    else
        local ls_dir="$1"
    fi
    local current_directory_dirs_out=$(ls -ap $1 | grep /; )
    local current_directory_files_out=$(ls -ap $1 | grep -v /; )

    local current_directory_status_out=""
    local top_lvl_git_dir=$(git rev-parse --show-toplevel 2> /dev/null)
    if [[ -n "$top_lvl_git_dir" ]]; then
        local current_directory_status_out=$(git status -s --ignored=no; )
        if [[ "" == "$current_directory_status_out" ]]; then
	        local current_directory_status_out=$(echo "Working tree clean."; )
	    fi
	    paste <(echo "$current_directory_dirs_out") <(echo "$current_directory_files_out") <(echo "$current_directory_status_out") | column -o "│" -s $'\t' -t -d -N C1,C2,C3 -T C1,C2,C3
	    return
    fi
    paste <(echo "$current_directory_dirs_out") <(echo "$current_directory_files_out") | column -o "│" -s $'\t' -t -d -N C1,C2 -T C1,C2
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
        (command tldr tldr) | less
    elif [[ $# -eq 1 ]]; then
        (command tldr "$1") | less
    else
        command tldr "$@"
    fi
}

_git-branch () {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

_suod () {
    bash ~/dotfiles/rc/rr/roll.sh
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
	local ORANGE="\033[38;5;214m" # requires terminal with 256bit colour support
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
	
	PS1+="\[${RED}\]\u\[${NOCOLOR}\]"
    
	# Current directory
	if [[ ! -z "$VIRTUAL_ENV" ]] ; then
        PS1+=" \[${LIGHTMAGENTA}\]\w (venv)\[${NOCOLOR}\]"
    else
        PS1+=" \[${BROWN}\]\w\[${DARKGRAY}\]" # working directory
    fi
    
    # active branch
    PS1+="\[${ORANGE}\]$(_git-branch)\[${NOCOLOR}\]"

	# Skip to the next line
	PS1+="\n"
    
    PS1+="\[${BLUE}\]\t\[${NOCOLOR}\] " # Time    
    
    PS1+="\[${GREEN}\]\$\[${NOCOLOR}\] " # $ 
    
	# PS2 is used to continue a command using the \ character
	PS2="\[${LIGHTGREEN}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${LIGHTRED}\]+\[${NOCOLOR}\] "
}
PROMPT_COMMAND='__setprompt'

# Alias's to modified commands
alias ps='ps auxf'
alias less='less -R'

# Change directory aliases
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
alias unxz="tar -xf"

# encryptions
alias md5="openssl md5"
alias sha1="openssl sha1"
alias sha256="openssl sha256"
alias sha512="openssl sha512"

#################### zachbrowne ##########################
##########################################################
# substitutes for commands
alias journalctl="_journalctl"
alias tldr="_tldr"
alias suod="_suod"
alias flatpak-log="flatpak remote-info --log flathub"
alias flatpak-checkout="flatpak update --commit="

# convenience alias
alias c="clear"
alias venv="source venv/bin/activate" # activate venv
alias vvenv="deactivate" # exit venv
alias cvenv="python -m venv venv" # create venv

alias restartpipewire="systemctl --user restart pipewire" # restart audio (pipewire)
alias restartnetworkmanager="systemctl restart NetworkManager" # restart internet (networkmanager)

alias reverse="tac"
alias palindrome="rev"

alias rm="rm -v"
alias ccat="bat --theme Dracula"
alias gedit="gnome-text-editor" # gedit replacement of choice
alias fuck='sudo $(history -p \!\!)'

source ~/.bashrc_private 2> /dev/null
