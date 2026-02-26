# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-26

### Added

- `dr-convert.sh` — AAC detection via ffprobe, lossless conversion to PCM via ffmpeg
- `dr-watch.sh` — inotifywait-based directory watcher daemon
- `install.sh` — interactive installer with `--dry-run` mode
- `uninstall.sh` — clean uninstaller with optional config removal
- `verify.sh` — pre-install audit: network call scan, checksums, GPG verification
- systemd user service (`dr-audio-watch`) with auto-start on login
- Nautilus right-click script: *Scripts → DR Audio Fix*
- DaVinci Resolve Python script (`Workspace → Scripts → dr_audio_fix`)
  with Tkinter GUI, progress bar, and Media Pool re-import
- `.deb` package for Debian/Ubuntu with postinst/prerm hooks
- AUR package (`PKGBUILD` + `.SRCINFO`) for Arch Linux
- GPG-signed releases with SHA256 checksums
- GitHub Actions CI: ShellCheck, Bandit, network audit, dry-run smoke test
- GitHub Actions Release: automated .deb build, checksum generation, GPG signing
- GitHub Actions AUR: auto-publish to AUR on new tag
- Support for `.mp4 .mov .mkv .avi .mts .m2ts .3gp .flv .wmv .mxf`
- Desktop notifications via `notify-send`
- Configurable: watch dirs, output format (MOV/MKV), delete-original option
