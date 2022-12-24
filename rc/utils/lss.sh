#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/math.sh"
source "$DIR/_git-branch.sh"

shopt -s globstar
shopt -s dotglob
shopt -s nullglob

__BLUE="27m"
__LIGHT_BLUE="39m"
__GREEN="34m"
__PALE_GREEN="42m"
__MAGENTA="127m"
__YELLOW="178m"
__RED="124m"
__WHITE="15m"
__BLACK="0m"

__PREFIX="\033["
__FOREGROUND="38;"
__BACKGROUND="48;"
__INFIX="5;"
__PFI="$__PREFIX$__FOREGROUND$__INFIX"
__PBI="$__PREFIX$__BACKGROUND$__INFIX"

_NOCOLOUR="\033[0m"
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
_FYELLOW="$__PFI$__YELLOW"
_BYELLOW="$__PBI$__YELLOW"
_BRED="$__PBI$__RED"
_FWHITE="$__PFI$__WHITE"
_BWHITE="$__PBI$__WHITE"
_FBLACK="$__PFI$__BLACK"

__colour_dir () {
    local ffn="$1"
    local bfn="$2"
    
    local ls_dir_sub=("$ffn/"*)
    local ls_dir_sub_count=${#ls_dir_sub[@]}
    
    local coloured_dir="$_FLBLUE$bfn$_NOCOLOUR"
    [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$_FBLUE$bfn$_NOCOLOUR"
    if [[ -h "$ffn" ]]; then
        local coloured_dir="$_BLBLUE$bfn$_NOCOLOUR"
        [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$_BBLUE$_FWHITE$bfn$_NOCOLOUR"
    fi
    
    echo "$coloured_dir"
}

__colour_file () {
    local ffn="$1"
    local bfn="$2"
    
    local ext="${bfn#*.}"
    local head=$(head -n 1 "$ffn" 2> /dev/null | tr -d '\0')
    
    local coloured_file="$bfn"
    [[ -h "$ffn" ]] && local coloured_file="$_BWHITE$_FBLACK$bfn$_NOCOLOUR"
    if [[ -x "$ffn" ]]; then
        local coloured_file="$_FGREEN$bfn$_NOCOLOUR"
        [[ -h "$ffn" ]] && local coloured_file="$_BGREEN$_FWHITE$bfn$_NOCOLOUR"
    fi
    
    case "$head" in
        "#!/usr/bin/env python"* | \
        "#!/usr/bin/python"* | \
        "#!python"*) 
            local coloured_file="$_FYELLOW$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BYELLOW$_FWHITE$bfn$_NOCOLOUR"
            ;;
        "#!/usr/bin/env bash"* | \
        "#!/bin/bash"* | \
        "#!/bin/sh"* | \
        "#/usr/local/bin/bash"* )
            local coloured_file="$_FPGREEN$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BPGREEN$_FWHITE$bfn$_NOCOLOUR"
            ;;
    esac
    
    case "$ext" in
        "py" | "pyc" | "pyo" | "pyd" )
            local coloured_file="$_FYELLOW$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BYELLOW$_FWHITE$bfn$_NOCOLOUR"
            ;; 
        "sh")
            local coloured_file="$_FPGREEN$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BPGREEN$_FWHITE$bfn$_NOCOLOUR"
            ;;
        "a" | ".ar" | "cpio" | "shar" | \
        "LBR" | "iso" | "lbr" | "mar" | "sbx" | \
        "tar" | "bz2" | "gz" | "lz" | "lz4" | \
        "lzma" | "xz" | "7z" | "zip" | "rar" | \
        "dmg" | "jar" | "pak" | "tar.gz" | "tgz" | \
        "tar.Z" | "tar.bz2" | "tbz2" | "tar.lz" | "tlz" | \
        "tar.xz" | "txz" | "tar.zst" | "xar" | "zipx" )
            local coloured_file="$_FMAGENTA$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BMAGENTA$_FWHITE$bfn$_NOCOLOUR"
            ;;
    esac
    
    echo "$coloured_file"
}

__colour_symlink () {
    local ffn="$1"
    local bfn="$2"
    
    echo "$_BRED$_FWHITE$bfn$_NOCOLOUR"
}

__unicode_girder () {
    [[ -z "$*" ]] && return
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
    
    local TERM_COLS="$(( $(tput cols) - 2))"
    local cursor_index=0
    local column_index=0
    local prev_column_width=1
    echo -n "$START_SYMBOL"
    for s in "${sizes[@]}"; do        
        for ((i=0; i<s; ++i)); do
            echo -n "$ROW_SYMBOL"
            ((++cursor_index))
            [[ $cursor_index -eq $TERM_COLS ]] && echo "" && return
        done
        
        local next_column_width="${sizes[column_index + 1]-0}"
        local prev_column_width="${sizes[column_index]}"
        ((++column_index))
        
        # special case, last column, skip the join symbol
        [[ $column_index -eq "${#sizes[@]}" ]] && break
        
        # special case, previous column is empty, skip the join symbol
        [[ "$prev_column_width" -eq 0 ]] && continue
        
        # special case, next column is empty, skip the join symbol
        [[ "$next_column_width" -eq 0 ]] && continue
        
        # special case, current column is empty, skip the join symbol
        [[ "$s" -eq 0 ]] && continue
        
        echo -n "$JOIN_SYMBOL"
    done
    echo "$END_SYMBOL"
}

lss () {
    # https://linuxhint.com/bash_operator_examples 
    # https://www.ditig.com/256-colors-cheat-sheet
    local ls_dir="${1-$PWD}/"
    [[ ! -d "$ls_dir" ]] && echo "Cannot access '$ls_dir': No such file or  directory" && return 2

    local git_dir_status_out=""
    if [[ -n "$(git -C "$ls_dir" rev-parse --show-toplevel 2> /dev/null)" ]]; then
        local git_dir_status_out="Working tree clean"
        [[ -n "$(git -C "$ls_dir" status -s --ignored=no)" ]] && local git_dir_status_out="Uncommited changes"
    fi

    local max_dir_size=0 # max dir name length
    local max_fn_size=0 # max file name length
    local dcount=0 # directory count
    local fcount=0 # file count
    local dirs=()
    local dirs_s=() # dir name sizes (before applying colours)
    local files=()
    local files_s=() # file name sizes (before applying colours)
    for ffn in "$ls_dir"*; do
        local bfn=$(basename -- "$ffn")
        
        # DIRECTORY
        if [[ -d "$ffn" ]]; then
            [[ ${#bfn} -gt $max_dir_size ]] && local max_dir_size=${#bfn}
            ((++dcount))
            dirs+=( "$(__colour_dir "$ffn" "$bfn" )" )
            dirs_s+=( "${#bfn}" )
        fi
        
        # FILE
        if [[ -f "$ffn" ]]; then
            [[ ${#bfn} -gt $max_fn_size ]] && local max_fn_size=${#bfn}
            ((++fcount))
            files+=( $(__colour_file "$ffn" "$bfn" ) )
            files_s+=( "${#bfn}" )
        fi 
        
        # SYMLINK (BROKEN)
        if [[ ! -e "$ffn" ]] && [[ -h "$ffn" ]]; then
            [[ ${#bfn} -gt $max_fn_size ]] && local max_fn_size=${#bfn}
            ((++fcount))
            files+=( $(__colour_symlink "$ffn" "$bfn" ) )
            files_s+=( "${#bfn}" )
        fi
    done
    
    # echo $(stat -c "%a" "$ffn") # print octet form permission
    # - 2 spaces for the girder, -2 for padding
    local TERM_LINES="$(( $(tput lines) - 4))"
    local TERM_COLS="$(( $(tput cols)))"
    # + 1 to make it 1 column if it's smaller than the screen size
    local dcolumns=$(((dcount / TERM_LINES) + 1))
    local fcolumns=$(((fcount / TERM_LINES) + 1))
    local drows=$(((dcount / dcolumns))) # if we have two columns, dirs are going to be split evenly etc.
    local frows=$(((fcount / dcolumns)))
    local di=0
    local fi=0
    local mcount=$(max "$drows" "$frows") 
    # if TERM_LINES is the minimum of the two, that means we have multiple columns in either side;
    #  meaning, that's the size to output regarding rows
    local mcount=$(min "$TERM_LINES" "$mcount") 
    echo "$dcount directories, $fcount files. $git_dir_status_out$(_git-branch "$ls_dir")"
    
    # if the directory is completely empty, stop
    [[ "$dcount" -eq 0 ]] && [[ "$fcount" -eq 0 ]] && return 0
    
    __unicode_girder --top $(( max_dir_size * dcolumns )) $(( max_fn_size * fcolumns ))
    for ((i=0;i<mcount;++i)); do
        # pad dir name
        local dl=""
        local dl_size=0
        local dl_size_overhead=0
        for ((k=0;k<dcolumns;++k)); do
            #if we're still in range...
            if [[ di -lt dcount ]]; then
                local dl+="${dirs[$di]}"
                local dl_size="${dirs_s[$di]}"
                local dl_size_overhead=$(( ${#dirs[$di]} - dl_size + dl_size_overhead))
            fi
            for ((j=dl_size;j<max_dir_size;++j)); do
                local dl+=' '
            done
            ((++di))
        done
        # pad file name
        local fl=""
        local fl_size=0
        local fl_size_overhead=0
        for ((k=0;k<fcolumns;++k)); do
            # if we're still in range...
            if [[ $fi -lt fcount ]]; then
                local fl+="${files[$fi]}"
                local fl_size="${files_s[$fi]}"
                local fl_size_overhead=$(( ${#files[$fi]} - fl_size + fl_size_overhead ))
            fi
            for ((j=fl_size;j<max_fn_size;++j)); do
                local fl+=' '
            done
            ((++fi))
        done
        local term_cols_with_overhead=$(( dl_size_overhead + fl_size_overhead + TERM_COLS ))
        local line_out=""
        [[ ! $dcount -eq 0 ]] && line_out+="│$dl"
        [[ ! $fcount -eq 0 ]] && line_out+="│$fl"
        [[ ! $fcount -eq 0 ]] || [[ ! $dcount -eq 0 ]] && line_out+="│"
        echo -e "${line_out:0:$term_cols_with_overhead}$_NOCOLOUR"
    done
    __unicode_girder --bot $(( max_dir_size * dcolumns )) $(( max_fn_size * fcolumns ))
}

export -f lss
