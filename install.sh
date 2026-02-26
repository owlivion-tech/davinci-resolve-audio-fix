#!/bin/bash
# install.sh — resolve-audio-fix installer
# https://github.com/owlivion/resolve-audio-fix
set -euo pipefail

REPO="https://github.com/owlivion/resolve-audio-fix"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-audio-fix"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
NAUTILUS_SCRIPTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
prompt()  { echo -e "${YELLOW}[?]${NC} $*"; }

echo ""
echo "  resolve-audio-fix — DaVinci Resolve AAC Audio Fix for Linux"
echo "  $REPO"
echo ""

# --- Dependency check ---
MISSING=()
command -v ffmpeg    &>/dev/null || MISSING+=("ffmpeg")
command -v ffprobe   &>/dev/null || MISSING+=("ffprobe")
command -v inotifywait &>/dev/null || MISSING+=("inotify-tools")

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing dependencies: ${MISSING[*]}"
    prompt "Install them now? (requires sudo) [Y/n]"
    read -r answer
    if [[ "${answer,,}" != "n" ]]; then
        sudo apt-get install -y ffmpeg inotify-tools
        info "Dependencies installed."
    else
        error "Please install dependencies manually and re-run install.sh"
    fi
fi

info "All dependencies satisfied."

# --- Watch directories ---
echo ""
prompt "Which directories should be watched for new videos?"
echo "  (space-separated, press Enter for default: \$HOME/Downloads)"
echo -n "  > "
read -r watch_input

if [[ -z "$watch_input" ]]; then
    WATCH_DIRS_INPUT="\$HOME/Downloads"
else
    WATCH_DIRS_INPUT="$watch_input"
fi

# --- Output format ---
echo ""
prompt "Output format? [mov/mkv] (default: mov)"
echo -n "  > "
read -r fmt_input
OUTPUT_FORMAT="${fmt_input:-mov}"
if [[ "$OUTPUT_FORMAT" != "mov" && "$OUTPUT_FORMAT" != "mkv" ]]; then
    warn "Unknown format '$OUTPUT_FORMAT', defaulting to mov."
    OUTPUT_FORMAT="mov"
fi

# --- Delete original ---
echo ""
prompt "Delete original file after conversion? [y/N] (default: no)"
echo -n "  > "
read -r del_input
if [[ "${del_input,,}" == "y" ]]; then
    DELETE_ORIGINAL="true"
else
    DELETE_ORIGINAL="false"
fi

# --- Create directories ---
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_DIR" "$NAUTILUS_SCRIPTS_DIR"

# --- Write config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat > "$CONFIG_DIR/dr-watch.conf" <<EOF
# resolve-audio-fix configuration
# Edit and then run: systemctl --user restart dr-audio-watch

WATCH_DIRS="$WATCH_DIRS_INPUT"
OUTPUT_FORMAT="$OUTPUT_FORMAT"
OUTPUT_SUFFIX="_dr"
DELETE_ORIGINAL="$DELETE_ORIGINAL"
NOTIFY="true"
EOF
info "Config written to $CONFIG_DIR/dr-watch.conf"

# --- Install scripts ---
install -m 755 "$SCRIPT_DIR/src/dr-convert.sh" "$BIN_DIR/dr-convert.sh"
install -m 755 "$SCRIPT_DIR/src/dr-watch.sh"   "$BIN_DIR/dr-watch.sh"
info "Scripts installed to $BIN_DIR"

# --- Install systemd service ---
install -m 644 "$SCRIPT_DIR/systemd/dr-audio-watch.service" "$SYSTEMD_DIR/dr-audio-watch.service"
systemctl --user daemon-reload
systemctl --user enable --now dr-audio-watch
info "Systemd service enabled and started."

# --- Install Nautilus script ---
install -m 755 "$SCRIPT_DIR/nautilus/DR Audio Fix" "$NAUTILUS_SCRIPTS_DIR/DR Audio Fix"
info "Nautilus right-click script installed."

echo ""
info "Installation complete!"
echo ""
echo "  Watch dirs : $WATCH_DIRS_INPUT"
echo "  Output     : <original>_dr.$OUTPUT_FORMAT"
echo "  Config     : $CONFIG_DIR/dr-watch.conf"
echo "  Logs       : ~/.local/share/resolve-audio-fix/convert.log"
echo ""
echo "  Manual convert : dr-convert.sh <file>"
echo "  Service status : systemctl --user status dr-audio-watch"
echo "  View logs      : journalctl --user -u dr-audio-watch -f"
echo ""
