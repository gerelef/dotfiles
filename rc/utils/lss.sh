#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/math.sh"
source "$DIR/_git-branch.sh"

shopt -s globstar
shopt -s dotglob
shopt -s nullglob

_unicode_table () {
    [[ -z "$@" ]] && return
    local START_SYMBOL="┌"
    local JOIN_SYMBOL="┬"
    local ROW_SYMBOL="─"
    local END_SYMBOL="┐"
    if [[ "$1" == "--bot" ]]; then
        local START_SYMBOL="└"
        local JOIN_SYMBOL="┴"
        local ROW_SYMBOL="─"
        local END_SYMBOL="┘"
    fi
    
    local sizes=()
    
    for arg in "${@:2}"; do
        local sizes+=( "$arg" )
    done
    
    local cc=1
    echo -n "$START_SYMBOL"
    for s in "${sizes[@]}"; do
        for ((i=0; i<$s; ++i)); do
            echo -n "$ROW_SYMBOL"
        done
        
        [[ $cc -lt "${#sizes[@]}" ]] && echo -n "$JOIN_SYMBOL"
        ((++cc))
    done
    echo "$END_SYMBOL"
}

lss () {
    # https://linuxhint.com/bash_operator_examples 
    # https://www.ditig.com/256-colors-cheat-sheet
    local ls_dir="$PWD/"
    [[ -z "$1" ]] || local ls_dir="$1/"
    if [[ ! -d "$ls_dir" ]]; then
        echo "Cannot access '$ls_dir': No such file or  directory"
        return 2
    fi
    
    local BLUE="27m"
    local LIGHT_BLUE="39m"
    local GREEN="34m"
    local PALE_GREEN="42m"
    local MAGENTA="127m"
    local YELLOW="178m"
    local RED="124m"
    local WHITE="15m"
    local BLACK="0m"
    
    local PREFIX="\033["
    local FOREGROUND="38;"
    local BACKGROUND="48;"
    local INFIX="5;"
	local NOCOLOUR="\033[0m"
	local PFI="$PREFIX$FOREGROUND$INFIX"
	local PBI="$PREFIX$BACKGROUND$INFIX"
	
	local F_BLUE="$PFI$BLUE"
	local B_BLUE="$PBI$BLUE"
	local F_LBLUE="$PFI$LIGHT_BLUE"
	local B_LBLUE="$PBI$LIGHT_BLUE"
	local F_GREEN="$PFI$GREEN"
	local B_GREEN="$PBI$GREEN"
	local F_PGREEN="$PFI$PALE_GREEN"
	local B_PGREEN="$PBI$PALE_GREEN"
	local F_MAGENTA="$PFI$MAGENTA"
	local B_MAGENTA="$PBI$MAGENTA"
	local F_YELLOW="$PFI$YELLOW"
	local B_YELLOW="$PBI$YELLOW"
	local F_RED="$PFI$RED"
	local B_RED="$PBI$RED"
	local F_WHITE="$PFI$WHITE"
	local B_WHITE="$PBI$WHITE"
	local F_BLACK="$PFI$BLACK"
	local B_BLACK="$PBI$BLACK"
	
	local TERM_LINES=$(tput lines)
    local TERM_COLS=$(tput cols)
    
    local git_dir_status_out=""
    if [[ -n "$(git -C "$ls_dir" rev-parse --show-toplevel 2> /dev/null)" ]]; then
        local git_dir_status=$(git -C "$ls_dir" status -s --ignored=no)
        local git_dir_status_out="Working tree clean"
        if [[ ! -z "$git_dir_status" ]]; then
            local git_dir_status_out="Uncommited changes"
        fi
    fi

    local max_dir_size=0
    local max_fn_size=0
    local max_sym_size=0
    
    # echo $(stat -c "%a" "$ffn") # print octet form permission    
    local dcount=0 # directory count
    local fcount=0 # file count
    local scount=0 # broken symlink count
    
    local bsym=()
    local bsym_s=()
    local dirs=()
    local dirs_s=()
    local files=()
    local files_s=()
    for ffn in "$ls_dir"*; do
        local bfn="$(basename -- $ffn)"
        
        # DIRECTORY
        if [[ -d "$ffn" ]]; then
            [[ ${#bfn} -gt $max_dir_size ]] && local max_dir_size=${#bfn}
            
            local ls_dir_sub=("$ffn/"*)
            local ls_dir_sub_count=${#ls_dir_sub[@]}
            
            local coloured_dir="$F_LBLUE$bfn$NOCOLOUR"
            [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$F_BLUE$bfn$NOCOLOUR"
            if [[ -h "$ffn" ]]; then
                local coloured_dir="$B_LBLUE$bfn$NOCOLOUR"
                [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$B_BLUE$F_WHITE$bfn$NOCOLOUR"
            fi
            
            ((++dcount))
            dirs+=( "$coloured_dir" )
            dirs_s+=( "${#bfn}" )
        fi
        
        # FILE
        if [[ -f "$ffn" ]]; then
            [[ ${#bfn} -gt $max_fn_size ]] && local max_fn_size=${#bfn}
            
            local ext="${bfn#*.}"
            local head=$(head -n 1 "$ffn" 2> /dev/null | tr -d '\0')
            
            local coloured_file="$NOCOLOUR$bfn"
            [[ -h "$ffn" ]] && local coloured_file="$B_WHITE$F_BLACK$bfn$NOCOLOUR"
            if [[ -x "$ffn" ]]; then
                local coloured_file="$F_GREEN$bfn$NOCOLOUR"
                [[ -h "$ffn" ]] && local coloured_file="$B_GREEN$F_WHITE$bfn$NOCOLOUR"
            fi
            
            case "$head" in
                "#!/usr/bin/env python"* | \
                "#!/usr/bin/python"* | \
                "#!python"*) 
                    local coloured_file="$F_YELLOW$bfn$NOCOLOUR"
                    [[ -h "$ffn" ]] && local coloured_file="$B_YELLOW$F_WHITE$bfn$NOCOLOUR"
                    ;;
                "#!/usr/bin/env bash"* | \
                "#!/bin/bash"* | \
                "#!/bin/sh"* | \
                "#!/bin/sh -"* | \
                "#/usr/local/bin/bash"* )
                    local coloured_file="$F_PGREEN$bfn$NOCOLOUR"
                    [[ -h "$ffn" ]] && local coloured_file="$B_PGREEN$F_WHITE$bfn$NOCOLOUR"
                    ;;
            esac
            
            case "$ext" in
                "py" | "pyc" | "pyo" | "pyd" )
                    local coloured_file="$F_YELLOW$bfn$NOCOLOUR"
                    [[ -h "$ffn" ]] && local coloured_file="$B_YELLOW$F_WHITE$bfn$NOCOLOUR"
                    ;; 
                "sh")
                    local coloured_file="$F_PGREEN$bfn$NOCOLOUR"
                    [[ -h "$ffn" ]] && local coloured_file="$B_PGREEN$F_WHITE$bfn$NOCOLOUR"
                    ;;
                "a" | ".ar" | "cpio" | "shar" | \
                "LBR" | "iso" | "lbr" | "mar" | "sbx" | \
                "tar" | "bz2" | "gz" | "lz" | "lz4" | \
                "lzma" | "xz" | "7z" | "zip" | "rar" | \
                "dmg" | "jar" | "pak" | "tar.gz" | "tgz" | \
                "tar.Z" | "tar.bz2" | "tbz2" | "tar.lz" | "tlz" | \
                "tar.xz" | "txz" | "tar.zst" | "xar" | "zipx" )
                    local coloured_file="$F_MAGENTA$bfn$NOCOLOUR" 
                    [[ -h "$ffn" ]] && local coloured_file="$B_MAGENTA$F_WHITE$bfn$NOCOLOUR"
                    ;;
            esac
            
            ((++fcount))
            files+=( "$coloured_file" )
            files_s+=( "${#bfn}" )
        fi 
        
        # SYMLINK (BROKEN)
        if [[ ! -e "$ffn" ]] && [[ -h "$ffn" ]]; then
            [[ ${#bfn} -gt $max_sym_size ]] && local max_sym_size=${#bfn}
            
            ((++scount))
            files+=( "$B_RED$F_WHITE$bfn$NOCOLOUR" )
            files_s+=( "${#bfn}" )
        fi
    done
    
    local dcolumns=$((($dcount / $TERM_LINES) + 1))
    local fcolumns=$((($fcount / $TERM_LINES) + 1))
    local di=0
    local fi=0
    local mcount=$(max $dcount $fcount $scount)
    echo "$dcount directories, $fcount files. $git_dir_status_out$(_git-branch $ls_dir)"
    _unicode_table --top $(( $max_dir_size * $dcolumns )) $(( $max_fn_size * $fcolumns ))
    for ((i=0;i<$mcount;++i)); do
        # pad dir name
        local dl=""
        local dl_size=0
        #if we're still in range...
        if [[ di -lt dcount ]]; then
            local dl="${dirs[$i]}"
            local dl_size="${dirs_s[$i]}"
        fi
        
        for ((j=$dl_size;j<$max_dir_size;++j)); do 
            local dl+=' '
        done
        ((++di))
        
        # pad file name
        local fl=""
        local fl_size=0
        if [[ fi -lt fcount ]]; then
            local fl="${files[$i]}"
            local fl_size="${files_s[$i]}"
        fi
        for ((j=$fl_size;j<$max_fn_size;++j)); do 
            local fl+=' '
        done
        ((++fi))
        
        echo -n "│"
        [[ ! $dcount -eq 0 ]] && echo -en "$dl"
        [[ ! $fcount -eq 0 ]] && echo -en "│$fl"
        echo "│"
    done
    _unicode_table --bot $(( $max_dir_size * $dcolumns )) $(( $max_fn_size * $fcolumns ))
}

export -f lss
