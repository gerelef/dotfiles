#!/usr/bin/env bash

# https://www.ditig.com/256-colors-cheat-sheet
__BLUE="27m"
__RED="124m"
__LIGHT_RED="196m"
__YELLOW="178m"
__GREEN="34m"
__PALE_GREEN="42m"
__LIGHT_BLUE="39m"
__MAGENTA="127m"
__LIGHT_MAGENTA="163m"
__BROWN="138m"
__WHITE="15m"
__BLACK="0m"

__PREFIX="\033["
__FOREGROUND="38;"
__BACKGROUND="48;"
__INFIX="5;" # https://man7.org/linux/man-pages/man4/console_codes.4.html
__PFI="$__PREFIX$__FOREGROUND$__INFIX"
__PBI="$__PREFIX$__BACKGROUND$__INFIX"

_NOCOLOUR="\033[0m"
_BOLD="\033[1m"
_UNDERLINE="\033[4m"
_BLINK="\033[5m"
_FBLUE="$__PFI$__BLUE"
_BBLUE="$__PBI$__BLUE"
_FLBLUE="$__PFI$__LIGHT_BLUE"
_BLBLUE="$__PBI$__LIGHT_BLUE"
_FGREEN="$__PFI$__GREEN"
_BGREEN="$__PBI$__GREEN"
_FPGREEN="$__PFI$__PALE_GREEN"
_BPGREEN="$__PBI$__PALE_GREEN"
_FMAGENTA="$__PFI$__MAGENTA"
_BMAGENTA="$__PBI$__MAGENTA"
_FMAGENTA="$__PFI$__LIGHT_MAGENTA"
_BMAGENTA="$__PBI$__LIGHT_MAGENTA"
_FYELLOW="$__PFI$__YELLOW"
_BYELLOW="$__PBI$__YELLOW"
_FRED="$__PFI$__RED"
_BRED="$__PBI$__RED"
_FRED="$__PFI$__LIGHT_RED"
_BRED="$__PBI$__LIGHT_RED"
_FBROWN="$__PFI$__BROWN"
_BBROWN="$__PBI$__BROWN"
_FWHITE="$__PFI$__WHITE"
_BWHITE="$__PBI$__WHITE"
_FBLACK="$__PFI$__BLACK"
_BBLACK="$__PBI$__BLACK"
