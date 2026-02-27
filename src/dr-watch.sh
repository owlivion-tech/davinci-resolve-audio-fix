#!/bin/bash
# dr-watch.sh — inotifywait-based folder watcher for resolve-audio-fix
# Part of resolve-audio-fix: https://github.com/owlivion-tech/davinci-resolve-audio-fix
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-audio-fix/dr-watch.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config not found: $CONFIG_FILE"
    echo "Run install.sh first."
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/resolve-audio-fix"
LOG_FILE="${LOG_FILE:-$LOG_DIR/convert.log}"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

if [[ -z "${WATCH_DIRS:-}" ]]; then
    log "ERROR: WATCH_DIRS is not set in config. Edit $CONFIG_FILE"
    exit 1
fi

read -ra ALL_DIRS <<< "$WATCH_DIRS"

VALID_DIRS=()
for dir in "${ALL_DIRS[@]}"; do
    expanded="${dir/\$HOME/$HOME}"
    expanded="${expanded/#\~/$HOME}"
    if [[ -d "$expanded" ]]; then
        VALID_DIRS+=("$expanded")
        log "Watching: $expanded"
    else
        log "WARNING: Directory not found, skipping: $expanded"
    fi
done

if [[ ${#VALID_DIRS[@]} -eq 0 ]]; then
    log "ERROR: No valid watch directories. Edit $CONFIG_FILE"
    exit 1
fi

log "resolve-audio-fix watcher started. PID: $$"

inotifywait -m -r \
    --event close_write \
    --event moved_to \
    --format '%w%f' \
    "${VALID_DIRS[@]}" 2>>"$LOG_FILE" | while IFS= read -r filepath; do

    [[ -f "$filepath" ]] || continue

    # Small delay — ensure file is fully written before processing
    sleep 2

    davinci-audio-fix "$filepath" 2>>"$LOG_FILE" || true
done
