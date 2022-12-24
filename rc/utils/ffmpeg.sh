#!/usr/bin/env bash

# convert Hours:Minutes:Seconds (colon seperated) to seconds 
hms () {
    echo "$1" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }';
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
        local trimmed_arg=${arg%.*}
        output_name+=$(head -c 4 <<< "$trimmed_arg")
        ((++count))
    done
    local output_name=$(head -c 30 <<< "$output_name")
    local output_name+="-concat$count.mp4"
    ffmpeg "${inputs[@]}" -filter_complex "$audio_video_ftracks concat=n=$count:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" -vsync cfr -r 60 "$output_name" 
}

# ffmpeg convert audio file to mp3
ffconvert-mp3 () {
    [[ -z "$*" ]] && return 2 
    for arg in "$@"; do
        local output=${arg%.*}
        ffmpeg -i "$arg" -acodec libmp3lame "$output-converted.mp3"
    done
}

# ffmpeg convert video file to mp4
ffconvert-mp4 () {
    [[ -z "$*" ]] && return 2 
    for arg in "$@"; do
        local output=${arg%.*}
        ffmpeg -i "$arg" -codec copy "$output-converted.mp4"
    done
}

# ffmpeg extract audio from video with audio to mp3
ffextract-audio-mp3 () {
    [[ -z "$*" ]] && return 2 
    for arg in "$@"; do
        local output=${arg%.*}
        ffmpeg -i "$arg" -vn "$output-audio.mp3"
    done
}

# ffmpeg extract video from video with audio to mp3
ffextract-video-mp4 () {
    [[ -z "$*" ]] && return 2 
    for arg in "$@"; do
        local output=${arg%.*}
        ffmpeg -i "$arg" -c copy -an "$output-video.mp4"
    done
}

# ffmpeg scale video file to selected resolution 
ffscale-mp4 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 width:height
    local output=${1%.*}
    ffmpeg -i "$1" -vf scale="$2" -vcodec libx265 -crf 22 -vsync cfr -r 60 "$output-scaled.mp4"
}

# ffmpeg trim mp3 from start to end
fftrim-mp3 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 start (seconds)
    # $3 duration (seconds)
    local output=${1%.*}
    ffmpeg -ss "$2" -t "$3" -i "$1" -acodec copy "$output-trimmed.mp3" 
}

# ffmpeg trim mp4 from start to end
fftrim-mp4 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 3 ]] && return 2
    # $1 input
    # $2 start (seconds)
    # $3 end   (seconds)
    local output=${1%.*}
    ffmpeg -ss "$2" -to "$3" -i "$1" -codec copy "$output-trimmed.mp4"
}

# ffmpeg compress mp3 audio
ffcompress-mp3 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 bitrate (e.g. 96k)
    local output=${1%.*}
    ffmpeg -i "$1" -map 0:a:0 -b:a "$2" "$output-compressed.mp3"
}

# ffmpeg compress mp4 video
ffcompress-mp4 () {
    [[ -z "$*" ]] && return 2 
    [[ "$#" -ne 2 ]] && return 2
    # $1 input
    # $2 crf logarithmic value for x265
    #  good values are from 27 to 30
    local output=${1%.*}
    ffmpeg -i "$1" -vcodec libx265 -crf "$2" -vsync cfr -r 60 "$output-compressed.mp4"
}

export -f ffcompress-mp4
export -f ffcompress-mp3
export -f fftrim-mp4
export -f fftrim-mp3
export -f ffscale-mp4
export -f ffextract-video-mp4
export -f ffextract-audio-mp3
export -f ffconvert-mp4
export -f ffconvert-mp3
export -f ffconcat-video
export -f hms
