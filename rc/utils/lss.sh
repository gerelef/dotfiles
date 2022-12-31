#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

if [[ -n "$__LSS_LOADED" ]]; then
    return 0
fi
readonly __LSS_LOADED="__LOADED"

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/math.sh"
source "$DIR/_git-branch.sh"
source "$DIR/colours.sh"
source "$DIR/fcolour.sh"

shopt -s globstar
shopt -s dotglob
shopt -s nullglob

__unicode_girder () {
    [[ -z "$*" ]] && return 2 
    
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

__padded_echo () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 name
    # $2 current size
    # $3 size to pad to
    
    local name="$1"
    local size="$2"
    local max_size="$3"
    
    for ((i=size;i<max_size;++i)); do
        local name+=' '
    done
    
    echo "$name"
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
            files+=( "$(__colour_file "$ffn" "$bfn" )" )
            files_s+=( "${#bfn}" )
        fi 
        
        # SYMLINK (BROKEN)
        if [[ ! -e "$ffn" ]] && [[ -h "$ffn" ]]; then
            [[ ${#bfn} -gt $max_fn_size ]] && local max_fn_size=${#bfn}
            ((++fcount))
            files+=( "$(__colour_symlink "$ffn" "$bfn" )" )
            files_s+=( "${#bfn}" )
        fi
    done
    
    # echo $(stat -c "%a" "$ffn") # print octet form permission
    # - 2 spaces for the girder, -2 for padding, -1 for the "N dirs N files" line
    local TERM_LINES="$(( $(tput lines) - 5))"
    local TERM_COLS="$(( $(tput cols)))"
    # + 1 to make it 1 column if it's smaller than the screen size
    local dcolumns=$(( (dcount / TERM_LINES) + 1))
    local fcolumns=$(( (fcount / TERM_LINES) + 1))
    local drows=$((dcount / dcolumns)) # if we have two columns, dirs are going to be split evenly, etc...
    local frows=$((fcount / fcolumns))
    
    # if the number of columns do not evenly fit the number of directories, add one
    [[ "$(is-factor "$dcolumns" "$dcount")" -ne 0 ]] && local drows=$((drows + 1)) 
    
    # if the number of columns do not evenly fit the number of directories, add one
    [[ "$(is-factor "$fcolumns" "$fcount")" -ne 0 ]] && local frows+=$((frows + 1))
    
    local di=0
    local fi=0
    local mcount=$(max "$drows" "$frows") 
    # if TERM_LINES is the minimum of the two, that means we have multiple columns in either side;
    #  meaning, that's the size to output regarding rows
    local mcount=$(min "$TERM_LINES" "$mcount") 
    echo "$dcount directories, $fcount files. $git_dir_status_out$(_git-branch "$ls_dir")"
    
    # if the directory is completely empty, stop
    [[ "$dcount" -eq 0 ]] && [[ "$fcount" -eq 0 ]] && return 0
    
    __unicode_girder --top "$(( max_dir_size * dcolumns ))" "$(( max_fn_size * fcolumns ))"
    for ((i=0;i<mcount;++i)); do
        # create & pad dir name
        local dl=""
        local dl_size_overhead=0
        for ((k=0;k<dcolumns;++k)); do
            #if we're still in range...
            if [[ "$di" -lt "$dcount" ]]; then
                local dl+="$(__padded_echo "${dirs[$di]}" "${dirs_s[$di]}" "$max_dir_size" )"
                local dl_size_overhead="$(( ${#dirs[$di]} - ${dirs_s[$di]} + dl_size_overhead))"
                ((++di))
            else
                local dl+="$(__padded_echo '' 0 "$max_dir_size")"
            fi
            
        done
        
        # create & pad file name
        local fl=""
        local fl_size_overhead=0
        for ((k=0;k<fcolumns;++k)); do
            # if we're still in range...
            if [[ "$fi" -lt "$fcount" ]]; then
                local fl+="$(__padded_echo "${files[$fi]}" "${files_s[$fi]}" "$max_fn_size" )"
                local fl_size_overhead="$(( ${#files[$fi]} - ${files_s[$fi]} + fl_size_overhead ))"
                ((++fi))
            else 
                # pad with empty string
                local fl+="$(__padded_echo '' 0 "$max_fn_size" )"
            fi
        done
        
        local line_out=""
        [[ ! "$dcount" -eq 0 ]] && line_out+="│$dl"
        [[ ! "$fcount" -eq 0 ]] && line_out+="│$fl"
        [[ ! "$fcount" -eq 0 ]] || [[ ! "$dcount" -eq 0 ]] && line_out+="│"
        
        local term_cols_with_overhead="$(( dl_size_overhead + fl_size_overhead + TERM_COLS ))"
        echo -e "${line_out:0:$term_cols_with_overhead}$_NOCOLOUR"
    done
    __unicode_girder --bot "$(( max_dir_size * dcolumns ))" "$(( max_fn_size * fcolumns ))"
}

export -f lss
