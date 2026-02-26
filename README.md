# resolve-audio-fix

**DaVinci Resolve on Linux does not support AAC audio.** This tool automatically detects and converts AAC audio in your video files to PCM — a format fully supported by DaVinci Resolve — without re-encoding the video stream.

## Why does this happen?

AAC is a patented codec. On Windows and macOS, the operating system provides AAC decoding at the system level (Windows Media Foundation / Apple CoreAudio). On Linux, no such system-level decoder exists for DaVinci Resolve to hook into — and Blackmagic Design has not bundled an alternative.

## Features

- **Auto watch** — monitors your chosen directories (Downloads, Videos, custom) for new video files
- **Smart detection** — only processes files with AAC audio, skips everything else
- **Lossless video** — video stream is copied as-is, no quality loss
- **Desktop notifications** — get notified when conversion starts and completes
- **Nautilus integration** — right-click any video file → *DR Audio Fix*
- **Systemd service** — starts automatically on login, restarts on failure
- **Configurable** — choose directories, output format (MOV/MKV), keep or delete originals

## Supported input formats

`mp4` `mov` `mkv` `avi` `mts` `m2ts` `3gp` `flv` `wmv` `mxf`

## Requirements

- Linux (Ubuntu/Debian-based recommended)
- `ffmpeg` + `ffprobe`
- `inotify-tools`
- `libnotify-bin` (for desktop notifications, optional)

## Installation

```bash
git clone https://github.com/owlivion/resolve-audio-fix.git
cd resolve-audio-fix
bash install.sh
```

The installer will:
1. Check and optionally install missing dependencies
2. Ask which directories to watch
3. Ask for output format preference
4. Install scripts to `~/.local/bin`
5. Enable the systemd user service
6. Add a Nautilus right-click script

## Configuration

Edit `~/.config/resolve-audio-fix/dr-watch.conf`:

```bash
# Directories to watch (space-separated)
WATCH_DIRS="$HOME/Downloads $HOME/Videos"

# Output format: mov (recommended) or mkv
OUTPUT_FORMAT="mov"

# Suffix for converted files (e.g. video_dr.mov)
OUTPUT_SUFFIX="_dr"

# Delete original after conversion
DELETE_ORIGINAL="false"

# Desktop notifications
NOTIFY="true"
```

After editing, restart the service:

```bash
systemctl --user restart dr-audio-watch
```

## Usage

### Automatic (watch mode)
Just drop video files into your watched directories. Converted files appear automatically as `filename_dr.mov` alongside the originals.

### Manual conversion
```bash
dr-convert.sh /path/to/video.mp4
dr-convert.sh /path/to/*.mp4   # batch
```

### Nautilus right-click
Select one or more video files in Nautilus → right-click → *Scripts* → *DR Audio Fix*

### Service management
```bash
systemctl --user status  dr-audio-watch   # status
systemctl --user restart dr-audio-watch   # restart
systemctl --user stop    dr-audio-watch   # stop
journalctl --user -u dr-audio-watch -f    # live logs
```

### View logs
```bash
cat ~/.local/share/resolve-audio-fix/convert.log
```

## Uninstall

```bash
bash uninstall.sh
```

## FAQ

**Will this re-encode my video?**
No. The video stream is copied directly (`-c:v copy`). Only the audio is re-encoded from AAC to PCM.

**Why PCM and not Opus/FLAC?**
DaVinci Resolve on Linux has the broadest support for PCM (uncompressed) audio. It is the safest choice.

**Why MOV and not MP4?**
MOV handles PCM audio more reliably than MP4. MKV is also available via the config.

**My file was not converted — why?**
Check the log file. Common reasons: audio is not AAC, output file already exists, or ffmpeg failed.

**Does this work with Kdenlive / OpenShot / other editors?**
Possibly, but this tool is designed and tested for DaVinci Resolve on Linux.

## Contributing

Pull requests are welcome. If you encounter a file format that is not handled correctly, please open an issue with the output of:

```bash
ffprobe -v quiet -print_format json -show_streams your_file.mp4
```

## License

MIT — see [LICENSE](LICENSE)
