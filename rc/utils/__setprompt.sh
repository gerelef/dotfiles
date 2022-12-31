#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

if [[ -n "$__PROMPT_LOADED" ]]; then
    return 0
fi
readonly __PROMPT_LOADED="__LOADED"

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/_git-branch.sh"
source "$DIR/colours.sh"

#################### zachbrowne ##########################
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c

#######################################################
# Set the ultimate amazing command prompt
#######################################################
function __setprompt
{
	local LAST_COMMAND=$? # Must come first!

	PROMPT_DIRTRIM=2

	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1="\[${_FRED}\]Exit Code \[${_FLRED}\]${LAST_COMMAND}\[${_NOCOLOUR}\] \[${_FRED}\]"
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
	
	PS1+="\[${_FLBLUE}\]\t\[${_NOCOLOUR}\]" # Time
	# PS1+="\[${_FRED}\]\u\[${_NOCOLOUR}\]" # User
    
	# Current directory
    PS1+=" \[${_FYELLOW}\]\w\[${_NOCOLOUR}\]" # working directory
    
    # active branch
    PS1+="\[${_FORANGE}\]$(_git-branch 2> /dev/null)\[${_NOCOLOUR}\]"

	# Skip to the next line
	PS1+="\n"    
	
    if [[ -n "$VIRTUAL_ENV" ]] ; then
        PS1+="\[${_FLMAGENTA}\]>>> \[${_NOCOLOUR}\]"
    else
        PS1+="\[${_FGREEN}\]\$\[${_NOCOLOUR}\] "
    fi
    
	# PS2 is used to continue a command using the \ character
	PS2="\[${_FPGREEN}\]>\[${_NOCOLOUR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${_FLRED}\]+\[${_NOCOLOUR}\] "
}

export -f __setprompt

#################### zachbrowne ##########################
##########################################################
