#!/bin/bash
# build_deb.sh — Build the .deb package for davinci-resolve-audio-fix
# Usage: bash packaging/build_deb.sh [version]
set -euo pipefail

VERSION="${1:-1.0.0}"
PACKAGE="davinci-resolve-audio-fix"
ARCH="all"
PKG_DIR="${PACKAGE}_${VERSION}_${ARCH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Building ${PKG_DIR}.deb ..."

# Clean previous build
rm -rf "$PKG_DIR"

# Create directory structure
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/usr/share/${PACKAGE}/config"
mkdir -p "${PKG_DIR}/usr/share/${PACKAGE}/systemd"
mkdir -p "${PKG_DIR}/usr/share/${PACKAGE}/nautilus"
mkdir -p "${PKG_DIR}/usr/share/${PACKAGE}/resolve_script"

# Executables → /usr/bin/
install -m 755 "${ROOT_DIR}/src/dr-convert.sh" "${PKG_DIR}/usr/bin/dr-convert"
install -m 755 "${ROOT_DIR}/src/dr-watch.sh"   "${PKG_DIR}/usr/bin/dr-watch"

# Shared data
install -m 644 "${ROOT_DIR}/config/dr-watch.conf" \
    "${PKG_DIR}/usr/share/${PACKAGE}/config/dr-watch.conf.example"

install -m 644 "${ROOT_DIR}/systemd/dr-audio-watch.service" \
    "${PKG_DIR}/usr/share/${PACKAGE}/systemd/"

install -m 755 "${ROOT_DIR}/nautilus/DR Audio Fix" \
    "${PKG_DIR}/usr/share/${PACKAGE}/nautilus/"

install -m 644 "${ROOT_DIR}/resolve_script/dr_audio_fix.py" \
    "${PKG_DIR}/usr/share/${PACKAGE}/resolve_script/"

# DEBIAN metadata
install -m 644 "${SCRIPT_DIR}/control"  "${PKG_DIR}/DEBIAN/control"
install -m 755 "${SCRIPT_DIR}/postinst" "${PKG_DIR}/DEBIAN/postinst"
install -m 755 "${SCRIPT_DIR}/prerm"    "${PKG_DIR}/DEBIAN/prerm"

# Inject correct version
sed -i "s/^Version:.*/Version: ${VERSION}/" "${PKG_DIR}/DEBIAN/control"

# Build
dpkg-deb --build --root-owner-group "$PKG_DIR"

echo ""
echo "  Built: ${PKG_DIR}.deb"
echo "  Size:  $(du -sh "${PKG_DIR}.deb" | cut -f1)"
