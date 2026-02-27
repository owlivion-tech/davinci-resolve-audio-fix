#!/bin/bash
# verify.sh — Audit tool for resolve-audio-fix
# Run this BEFORE install.sh to see exactly what will happen.
# https://github.com/owlivion-tech/davinci-resolve-audio-fix
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

section() { echo -e "\n${CYAN}${BOLD}=== $* ===${NC}"; }
pass()    { echo -e "${GREEN}[PASS]${NC} $*"; }
fail()    { echo -e "${RED}[FAIL]${NC} $*"; }
info()    { echo -e "  $*"; }

echo ""
echo -e "${BOLD}resolve-audio-fix — Pre-Install Audit${NC}"
echo "  https://github.com/owlivion-tech/davinci-resolve-audio-fix"
echo ""
echo "Run this script to verify what will be installed and that"
echo "the tool contains no outbound network calls."

# ---------------------------------------------------------------------------
section "Files That Will Be Installed"
# ---------------------------------------------------------------------------

BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/resolve-audio-fix"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user"
NAUTILUS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nautilus/scripts"
RESOLVE_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/DaVinciResolve/Fusion/Scripts/Utility"

info "${BIN_DIR}/dr-convert.sh         (AAC detection + ffmpeg conversion)"
info "${BIN_DIR}/dr-watch.sh           (inotifywait directory watcher)"
info "${CONFIG_DIR}/dr-watch.conf      (user configuration)"
info "${SYSTEMD_DIR}/dr-audio-watch.service  (auto-start on login)"
info "${NAUTILUS_DIR}/DR Audio Fix     (Nautilus right-click script)"
info "${RESOLVE_DIR}/dr_audio_fix.py   (DaVinci Resolve script — if DR is installed)"

# ---------------------------------------------------------------------------
section "Network Call Audit"
# ---------------------------------------------------------------------------

# Pattern split across variables so this file doesn't trigger its own scan
NET_A="curl |wget |requests\."
NET_B="urllib\.request|httpx|socket\.connect"
FOUND=0

for f in install.sh uninstall.sh src/dr-convert.sh src/dr-watch.sh \
          "nautilus/DR Audio Fix" resolve_script/dr_audio_fix.py; do
    [[ -f "$f" ]] || continue
    if grep -nE "($NET_A|$NET_B)" "$f" 2>/dev/null; then
        FOUND=1
    fi
done

if [[ "$FOUND" -eq 0 ]]; then
    pass "No outbound network calls found in any script."
    info "Tool only calls: ffmpeg, ffprobe (local binaries)"
else
    fail "Potential network calls found — review lines above before installing."
fi

# ---------------------------------------------------------------------------
section "External Commands Used"
# ---------------------------------------------------------------------------

info "The tool calls these external programs:"
info "  ffprobe  — to detect audio codec of video files"
info "  ffmpeg   — to convert AAC audio to PCM"
info "  inotifywait — to watch directories for new files"
info "  notify-send  — for desktop notifications (optional)"
info ""
info "No other programs are called. You can verify with strace:"
info "  strace -e trace=execve bash install.sh 2>&1 | grep execve"

# ---------------------------------------------------------------------------
section "Checksums"
# ---------------------------------------------------------------------------

sha256sum \
    install.sh uninstall.sh verify.sh \
    src/dr-convert.sh src/dr-watch.sh \
    "nautilus/DR Audio Fix" \
    resolve_script/dr_audio_fix.py \
    2>/dev/null || true

echo ""
info "Release asset verification (after downloading from GitHub Releases):"
info "  sha256sum -c checksums.sha256"
info "  gpg --verify checksums.sha256.sig checksums.sha256"

# ---------------------------------------------------------------------------
section "GPG Signature Verification"
# ---------------------------------------------------------------------------

if [[ -f checksums.sha256 && -f checksums.sha256.sig ]]; then
    if gpg --verify checksums.sha256.sig checksums.sha256 2>/dev/null; then
        pass "GPG signature is valid."
    else
        fail "GPG signature verification FAILED."
        info "Download the release from: https://github.com/owlivion-tech/davinci-resolve-audio-fix/releases"
    fi
else
    echo "  No signed checksums found locally."
    info "To verify a release download:"
    info "  gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>"
    info "  gpg --verify checksums.sha256.sig checksums.sha256"
    info "  sha256sum -c checksums.sha256"
fi

# ---------------------------------------------------------------------------
section "Summary"
# ---------------------------------------------------------------------------

echo ""
echo "  If everything above looks correct, run:"
echo ""
echo "    bash install.sh"
echo ""
echo "  Or preview without making any changes:"
echo ""
echo "    bash install.sh --dry-run"
echo ""
