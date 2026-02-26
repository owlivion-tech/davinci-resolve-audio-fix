#!/bin/bash
# dr-convert.sh — AAC detection and conversion for DaVinci Resolve on Linux
# Part of resolve-audio-fix: https://github.com/owlivion/resolve-audio-fix
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-audio-fix/dr-watch.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

OUTPUT_FORMAT="${OUTPUT_FORMAT:-mov}"
OUTPUT_SUFFIX="${OUTPUT_SUFFIX:-_dr}"
DELETE_ORIGINAL="${DELETE_ORIGINAL:-false}"
NOTIFY="${NOTIFY:-true}"
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/resolve-audio-fix"
LOG_FILE="${LOG_FILE:-$LOG_DIR/convert.log}"

mkdir -p "$LOG_DIR"

VIDEO_EXTENSIONS="mp4 mov mkv avi mts m2ts 3gp flv wmv mxf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

notify() {
    if [[ "$NOTIFY" == "true" ]] && command -v notify-send &>/dev/null; then
        notify-send --icon="${3:-video-x-generic}" "$1" "$2"
    fi
}

is_video_file() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"
    for e in $VIDEO_EXTENSIONS; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

convert_file() {
    local input="$1"

    if [[ ! -f "$input" ]]; then
        log "ERROR: File not found: $input"
        return 1
    fi

    if ! is_video_file "$input"; then
        return 0
    fi

    # Skip already converted files
    local basename="${input%.*}"
    if [[ "$basename" == *"$OUTPUT_SUFFIX" ]]; then
        log "SKIP: Already converted: $input"
        return 0
    fi

    # Check audio codec
    local audio_codec
    audio_codec=$(ffprobe -v quiet \
        -select_streams a:0 \
        -show_entries stream=codec_name \
        -of csv=p=0 \
        "$input" 2>/dev/null || true)

    if [[ "$audio_codec" != "aac" ]]; then
        log "SKIP: Audio codec '$audio_codec' is not AAC: $(basename "$input")"
        return 0
    fi

    local output="${basename}${OUTPUT_SUFFIX}.${OUTPUT_FORMAT}"

    if [[ -f "$output" ]]; then
        log "SKIP: Output already exists: $(basename "$output")"
        return 0
    fi

    log "CONVERTING: $(basename "$input") → $(basename "$output")"
    notify "resolve-audio-fix" "Converting: $(basename "$input")"

    if ffmpeg -i "$input" -c:v copy -c:a pcm_s16le "$output" -y 2>>"$LOG_FILE"; then
        log "SUCCESS: $(basename "$output")"
        notify "resolve-audio-fix" "Done: $(basename "$output")"

        if [[ "$DELETE_ORIGINAL" == "true" ]]; then
            rm "$input"
            log "DELETED original: $(basename "$input")"
        fi
    else
        log "ERROR: Conversion failed for: $(basename "$input")"
        notify "resolve-audio-fix" "Error: $(basename "$input")" "dialog-error"
        [[ -f "$output" ]] && rm "$output"
        return 1
    fi
}

if [[ $# -eq 0 ]]; then
    echo "Usage: dr-convert.sh <file> [file2 ...]"
    exit 1
fi

for file in "$@"; do
    convert_file "$file"
done
