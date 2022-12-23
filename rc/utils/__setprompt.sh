#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/_git-branch.sh"

#################### zachbrowne ##########################
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c

#######################################################
# Set the ultimate amazing command prompt
#######################################################
function __setprompt
{
	local LAST_COMMAND=$? # Must come first!

	# Define colors
	local RED="\033[0;31m"
	local LIGHTRED="\033[1;31m"
	local YELLOW="\033[1;33m"
	local GREEN="\033[0;32m"
	local LIGHTGREEN="\033[1;32m"
	local BROWN="\033[0;33m"
	local BLUE="\033[0;34m"
	local LIGHTMAGENTA="\033[1;35m"
	local NOCOLOR="\033[0m"

	PROMPT_DIRTRIM=2

	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1="\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${NOCOLOR}\] \[${RED}\]"
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
	
	PS1+="\[${BLUE}\]\t\[${NOCOLOR}\]" # Time
	# PS1+="\[${RED}\]\u\[${NOCOLOR}\]" # User
    
	# Current directory
    PS1+=" \[${BROWN}\]\w\[${NOCOLOR}\]" # working directory
    
    # active branch
    PS1+="\[${YELLOW}\]$(_git-branch 2> /dev/null)\[${NOCOLOR}\]"

	# Skip to the next line
	PS1+="\n"    
	
    if [[ ! -z "$VIRTUAL_ENV" ]] ; then
        PS1+="\[${LIGHTMAGENTA}\]>>>\[${NOCOLOR}\]"
    else
        PS1+="\[${GREEN}\]\$\[${NOCOLOR}\] "
    fi
    
	# PS2 is used to continue a command using the \ character
	PS2="\[${LIGHTGREEN}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${LIGHTRED}\]+\[${NOCOLOR}\] "
}

export -f __setprompt

#################### zachbrowne ##########################
##########################################################
