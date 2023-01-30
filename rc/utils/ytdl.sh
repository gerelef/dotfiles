#!/usr/bin/env bash

if [[ -n "$__YTDL_LOADED" ]]; then
    return 0
fi
readonly __YTDL_LOADED="__LOADED"
REQUIRE_DEPENDENCIES+="yt-dlp yt-dlp-bash-completion "

# yt-dlp download to mp3
ytdl-mp3 () {
    [[ -z "$*" ]] && return 2 
    
    yt-dlp --extract-audio --audio-format mp3 --audio-quality 0 "$@" 
}

# yt-dlp download to mp4
ytdl-mp4 () {
    [[ -z "$*" ]] && return 2
    
    yt-dlp --format "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" "$@"
}

export -f ytdl-mp3
export -f ytdl-mp4
