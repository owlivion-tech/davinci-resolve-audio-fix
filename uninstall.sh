#!/bin/bash
# uninstall.sh — resolve-audio-fix uninstaller
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-audio-fix"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
NAUTILUS_SCRIPTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts"

echo "Uninstalling resolve-audio-fix..."

if systemctl --user disable --now dr-audio-watch 2>/dev/null; then
    echo "[✓] Service stopped and disabled."
fi

rm -f "$SYSTEMD_DIR/dr-audio-watch.service"
systemctl --user daemon-reload

rm -f "$BIN_DIR/dr-convert.sh" "$BIN_DIR/dr-watch.sh"
rm -f "$NAUTILUS_SCRIPTS_DIR/DR Audio Fix"

echo -n "[?] Remove config and logs too? [y/N] "
read -r answer
if [[ "${answer,,}" == "y" ]]; then
    rm -rf "$CONFIG_DIR"
    rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/resolve-audio-fix"
    echo "[✓] Config and logs removed."
fi

echo "[✓] resolve-audio-fix uninstalled."
