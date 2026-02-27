#!/bin/bash
# install.sh — resolve-audio-fix installer
# https://github.com/owlivion-tech/davinci-resolve-audio-fix
set -euo pipefail

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
DRY_RUN="false"
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN="true" ;;
    esac
done

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO="https://github.com/owlivion-tech/davinci-resolve-audio-fix"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-audio-fix"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
NAUTILUS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts"
RESOLVE_SCRIPT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/DaVinciResolve/Fusion/Scripts/Utility"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
error()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }
prompt() { echo -e "${YELLOW}[?]${NC} $*"; }
dry()    { echo -e "${CYAN}[DRY-RUN]${NC} $*"; }

# Helper: run or simulate a command
run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        dry "$*"
    else
        "$@"
    fi
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
echo ""
echo "  resolve-audio-fix — DaVinci Resolve AAC Audio Fix for Linux"
echo "  $REPO"
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "  ${CYAN}DRY-RUN MODE — no changes will be made${NC}"
fi
echo ""

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
MISSING=()
command -v ffmpeg      &>/dev/null || MISSING+=("ffmpeg")
command -v ffprobe     &>/dev/null || MISSING+=("ffprobe")
command -v inotifywait &>/dev/null || MISSING+=("inotify-tools")

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing dependencies: ${MISSING[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        dry "Would run: sudo apt-get install -y ffmpeg inotify-tools"
    else
        prompt "Install them now? (requires sudo) [Y/n]"
        read -r answer
        if [[ "${answer,,}" != "n" ]]; then
            sudo apt-get install -y ffmpeg inotify-tools
            info "Dependencies installed."
        else
            error "Please install dependencies manually and re-run install.sh"
        fi
    fi
else
    info "All dependencies satisfied."
fi

# ---------------------------------------------------------------------------
# Interactive prompts (skip in dry-run with defaults)
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
    WATCH_DIRS_INPUT="\$HOME/Downloads"
    OUTPUT_FORMAT="mov"
    DELETE_ORIGINAL="false"
    dry "Would ask: watch directories  → using default: \$HOME/Downloads"
    dry "Would ask: output format      → using default: mov"
    dry "Would ask: delete originals   → using default: no"
else
    # Watch directories
    echo ""
    prompt "Which directories should be watched for new videos?"
    echo "  (space-separated, press Enter for default: \$HOME/Downloads)"
    echo -n "  > "
    read -r watch_input
    WATCH_DIRS_INPUT="${watch_input:-\$HOME/Downloads}"

    # Output format
    echo ""
    prompt "Output format? [mov/mkv] (default: mov)"
    echo -n "  > "
    read -r fmt_input
    OUTPUT_FORMAT="${fmt_input:-mov}"
    if [[ "$OUTPUT_FORMAT" != "mov" && "$OUTPUT_FORMAT" != "mkv" ]]; then
        warn "Unknown format '$OUTPUT_FORMAT', defaulting to mov."
        OUTPUT_FORMAT="mov"
    fi

    # Delete original
    echo ""
    prompt "Delete original file after conversion? [y/N] (default: no)"
    echo -n "  > "
    read -r del_input
    DELETE_ORIGINAL="false"
    [[ "${del_input,,}" == "y" ]] && DELETE_ORIGINAL="true"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------------------
echo ""
run mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_DIR" "$NAUTILUS_DIR"

# ---------------------------------------------------------------------------
# Write config
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would write config → $CONFIG_DIR/dr-watch.conf"
    dry "  WATCH_DIRS=\"$WATCH_DIRS_INPUT\""
    dry "  OUTPUT_FORMAT=\"$OUTPUT_FORMAT\""
    dry "  DELETE_ORIGINAL=\"$DELETE_ORIGINAL\""
else
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
fi

# ---------------------------------------------------------------------------
# Install scripts
# ---------------------------------------------------------------------------
run install -m 755 "$SCRIPT_DIR/src/dr-convert.sh" "$BIN_DIR/davinci-audio-fix"
run install -m 755 "$SCRIPT_DIR/src/dr-watch.sh"   "$BIN_DIR/davinci-audio-watchd"
[[ "$DRY_RUN" != "true" ]] && info "Scripts installed to $BIN_DIR"

# ---------------------------------------------------------------------------
# Install systemd service
# ---------------------------------------------------------------------------
run install -m 644 "$SCRIPT_DIR/systemd/dr-audio-watch.service" \
    "$SYSTEMD_DIR/dr-audio-watch.service"

if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would run: systemctl --user daemon-reload"
    dry "Would run: systemctl --user enable --now dr-audio-watch"
else
    systemctl --user daemon-reload
    systemctl --user enable --now dr-audio-watch
    info "Systemd service enabled and started."
fi

# ---------------------------------------------------------------------------
# Install Nautilus script
# ---------------------------------------------------------------------------
run install -m 755 "$SCRIPT_DIR/nautilus/DR Audio Fix" "$NAUTILUS_DIR/DR Audio Fix"
[[ "$DRY_RUN" != "true" ]] && info "Nautilus right-click script installed."

# ---------------------------------------------------------------------------
# Install DaVinci Resolve script (if DR is present)
# ---------------------------------------------------------------------------
RESOLVE_BIN="/opt/resolve/bin/resolve"
if [[ -f "$RESOLVE_BIN" ]]; then
    run mkdir -p "$RESOLVE_SCRIPT_DIR"
    run install -m 644 "$SCRIPT_DIR/resolve_script/dr_audio_fix.py" \
        "$RESOLVE_SCRIPT_DIR/dr_audio_fix.py"
    if [[ "$DRY_RUN" != "true" ]]; then
        info "DaVinci Resolve script installed → Workspace → Scripts → dr_audio_fix"
    fi
else
    warn "DaVinci Resolve not found at $RESOLVE_BIN — skipping Resolve script install."
    warn "To install manually: cp resolve_script/dr_audio_fix.py $RESOLVE_SCRIPT_DIR/"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${CYAN}Dry-run complete. No files were modified.${NC}"
    echo "  Run without --dry-run to perform the actual installation."
else
    info "Installation complete!"
    echo ""
    echo "  Watch dirs : $WATCH_DIRS_INPUT"
    echo "  Output     : <original>_dr.$OUTPUT_FORMAT"
    echo "  Config     : $CONFIG_DIR/dr-watch.conf"
    echo "  Logs       : ~/.local/share/resolve-audio-fix/convert.log"
    echo ""
    echo "  Manual convert : davinci-audio-fix <file>"
    echo "  Service status : systemctl --user status dr-audio-watch"
    echo "  View logs      : journalctl --user -u dr-audio-watch -f"
fi
echo ""
