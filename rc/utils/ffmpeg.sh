#!/usr/bin/env bash

if [[ -n "$__FFMPEG_WRAP_LOADED" ]]; then
    return 0
fi
readonly __FFMPEG_WRAP_LOADED="__LOADED"
REQUIRE_DEPENDENCIES+="ffmpeg "

# convert Minutes:Seconds (colon seperated) to seconds
__hms () {
    echo "$1" | awk -F: '{ print ($1 * 60) + $2 }';
}

# convert (X,Y) coords with X delimiter instead of comma to ffmpeg format
__xy_to_ffilter_coords () {
    echo "$1" | awk -Fx '{ print $1":"$2 }';
}

# convert (X1,Y1) (X2,Y2) coords with X delimiter instead of comma to ffmpeg format (X2-X1,Y2-Y1)
__xy_rp_to_ffilter_coords () {
    echo "$@" | awk -F'[x ]' '{ print $3-$1":"$4-$2 }';
}

# ffmpeg concatenate multiple video files into one
#  INPUTS: files >= 2
ffconcat-video () {
    [[ -z "$*" ]] && return 2
    
    local inputs=()
    local audio_video_ftracks=""
    local trimmed_arg=""
    local output_name=""
    local count=0
    for arg in "$@"; do
        local inputs+=( -i "$arg" )
        local audio_video_ftracks+="[$count:v] [$count:a] "
        local trimmed_arg="$(basename -- ${arg%.*})"
        local output_name+=$(head -c 4 <<< "$trimmed_arg")
        ((++count))
    done
    local output_name=$(head -c 30 <<< "$output_name")
    local output_name+="-concat$count.mp4"
    ffmpeg "${inputs[@]}" -filter_complex "$audio_video_ftracks concat=n=$count:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" -vsync cfr -r 60 "$PWD/$output_name" 
}

# ffmpeg convert audio file to mp3
ffconvert-mp3 () {
    [[ -z "$*" ]] && return 2 
    for arg in "$@"; do
        local output=$(basename -- "${arg%.*}")
        ffmpeg -i "$arg" -acodec libmp3lame "$PWD/$output-converted.mp3"  1> /dev/null
        echo "Done $output-converted"
    done
}

# ffmpeg convert video file to mp4
ffconvert-mp4 () {
    [[ -z "$*" ]] && return 2
    for arg in "$@"; do
        local output=$(basename -- "${arg%.*}")
        ffmpeg -i "$arg" -codec copy "$PWD/$output-converted.mp4" 1> /dev/null
        echo "Done $output-converted"
    done
}

# ffmpeg extract audio from video with audio to mp3
ffextract-audio-mp3 () {
    [[ -z "$*" ]] && return 2
    for arg in "$@"; do
        local output=$(basename -- "${arg%.*}")
        ffmpeg -i "$arg" -vn "$PWD/$output-audio.mp3" 1> /dev/null
        echo "Done $output-audio"
    done
}

# ffmpeg extract video from video with audio to mp3
ffextract-video-mp4 () {
    [[ -z "$*" ]] && return 2
    for arg in "$@"; do
        local output=$(basename -- "${arg%.*}")
        ffmpeg -i "$arg" -c copy -an "$PWD/$output-video.mp4" 1> /dev/null
        echo "Done $output-video"
    done
}

ffvideofy () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 image
    # $2 audio
    local output=$(basename -- "${1%.*}")
    local output+=$(basename -- "${2%.*}")
    
    ffmpeg -loop 1 -y -i "$1" -i "$2" -vcodec libx265 -shortest "$PWD/$output.mp4"
}

# ffmpeg trim mp4 from start to end and convert to gif
ffgiphify () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 start m:s 
    # $3 end   m:s
    local output=$(basename -- "${1%.*}")
    local palette="/tmp/$output-palette.png"
    ffmpeg -i "$1" -filter_complex "[0:v] palettegen" "$palette" 1> /dev/null
    ffmpeg -ss "$(__hms "$2")" -to "$(__hms "$3")" -i "$1" -i "$palette" -filter_complex "[0:v] paletteuse" "$PWD/$output-giphified.gif" 1> /dev/null
    rm -v "$palette"
    echo "Done $output-giphified"
}

# ffmpeg crop section of a clip
ffcrop-mp4 () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 starting position (starting from (0,0) on top left)
    # $3 ending position (starting from (0,0) on top left)
    local output=$(basename -- "${1%.*}")
    ffmpeg -i "$1" -filter:v "crop=$(__xy_rp_to_ffilter_coords "$2" "$3"):$(__xy_to_ffilter_coords "$2")" "$PWD/$output-cropped.mp4"
}

# ffmpeg scale video file to selected resolution
ffscale-mp4 () {
    [[ -z "$*" ]] && return 2
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 width:height
    local output=$(basename -- "${1%.*}")
    ffmpeg -i "$1" -vf scale="$(__xy_to_ffilter_coords "$2")" -vcodec libx265 -crf 22 -vsync cfr -r 60 "$PWD/$output-scaled.mp4"
}

# ffmpeg trim mp3 from start to end
fftrim-mp3 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 start (seconds)
    # $3 duration (seconds)
    local output=$(basename -- "${1%.*}")
    ffmpeg -ss "$(__hms "$2")" -to "$(__hms "$3")" -i "$1" -acodec copy "$PWD/$output-trimmed.mp3" 
}

# ffmpeg trim mp4 from start to end
fftrim-mp4 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 start (seconds)
    # $3 end   (seconds)
    local output=$(basename -- "${1%.*}")
    ffmpeg -ss "$(__hms "$2")" -to "$(__hms "$3")" -i "$1" -codec copy "$PWD/$output-trimmed.mp4"
}

# ffmpeg compress mp3 audio
ffcompress-mp3 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 bitrate (e.g. 96k)
    local output=$(basename -- "${1%.*}")
    ffmpeg -i "$1" -map 0:a:0 -b:a "$2" "$PWD/output-compressed.mp3"
}

# ffmpeg compress mp4 video
ffcompress-mp4 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 crf logarithmic value for x265
    #  good values are from 27 to 30
    local output=$(basename -- "${1%.*}")
    ffmpeg -i "$1" -vcodec libx265 -crf "$2" -vsync cfr -r 60 "$PWD/$output-compressed.mp4"
}

export -f ffcompress-mp4
export -f ffcompress-mp3
export -f fftrim-mp4
export -f fftrim-mp3
export -f ffvideofy
export -f ffgiphify
export -f ffcrop-mp4
export -f ffscale-mp4
export -f ffextract-video-mp4
export -f ffextract-audio-mp3
export -f ffconvert-mp4
export -f ffconvert-mp3
export -f ffconcat-video
