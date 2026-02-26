#!/usr/bin/env python3
"""
dr_audio_fix.py — DaVinci Resolve Utility Script

Detects AAC audio clips in the current Media Pool folder and converts
them to PCM — the format fully supported by DaVinci Resolve on Linux.

Installation:
    cp dr_audio_fix.py ~/.local/share/DaVinciResolve/Fusion/Scripts/Utility/

Usage inside DaVinci Resolve:
    Workspace → Scripts → dr_audio_fix

https://github.com/owlivion/resolve-audio-fix
"""

import os
import sys
import subprocess
import threading
import tkinter as tk
from tkinter import ttk, scrolledtext
from typing import Optional

# ---------------------------------------------------------------------------
# DaVinci Resolve API
# ---------------------------------------------------------------------------

RESOLVE_API_PATH = "/opt/resolve/Developer/Scripting/Modules"


def _connect_resolve():
    if RESOLVE_API_PATH not in sys.path:
        sys.path.insert(0, RESOLVE_API_PATH)
    try:
        import DaVinciResolveScript as dvr  # noqa: PLC0415
        return dvr.scriptapp("Resolve")
    except (ImportError, Exception):
        return None


# ---------------------------------------------------------------------------
# Audio utilities (local only — no network)
# ---------------------------------------------------------------------------

def get_audio_codec(filepath: str) -> str:
    """Return the audio codec name of the first audio stream, or empty string."""
    try:
        result = subprocess.run(
            [
                "ffprobe", "-v", "quiet",
                "-select_streams", "a:0",
                "-show_entries", "stream=codec_name",
                "-of", "csv=p=0",
                filepath,
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def convert_to_pcm(
    filepath: str,
    suffix: str = "_dr",
    fmt: str = "mov",
) -> Optional[str]:
    """
    Convert audio stream to PCM (S16LE), copy video stream unchanged.
    Returns output path on success, None on failure.
    """
    base, _ = os.path.splitext(filepath)
    output = f"{base}{suffix}.{fmt}"

    if os.path.exists(output):
        return output  # already converted

    try:
        result = subprocess.run(
            [
                "ffmpeg", "-i", filepath,
                "-c:v", "copy",
                "-c:a", "pcm_s16le",
                output, "-y",
            ],
            capture_output=True,
            timeout=600,
        )
        return output if result.returncode == 0 else None
    except Exception:
        return None


# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------

BG_DARK   = "#0d1117"
BG_MID    = "#161b22"
BG_MAIN   = "#1a1a2e"
FG_TEXT   = "#c9d1d9"
FG_MUTED  = "#8b949e"
FG_BLUE   = "#58a6ff"
FG_GREEN  = "#56d364"
FG_RED    = "#f85149"
BTN_GREEN = "#238636"
BTN_GRAY  = "#21262d"


class DrAudioFixApp:

    def __init__(self, root: tk.Tk, resolve=None):
        self.root = root
        self.resolve = resolve
        self.running = False

        root.title("resolve-audio-fix")
        root.resizable(False, False)
        root.configure(bg=BG_MAIN)

        self._build_ui()

    def _build_ui(self):
        # Header
        header = tk.Frame(self.root, bg=BG_DARK, pady=14)
        header.pack(fill="x")

        tk.Label(
            header,
            text="resolve-audio-fix",
            font=("Courier New", 18, "bold"),
            fg=FG_BLUE, bg=BG_DARK,
        ).pack()

        tk.Label(
            header,
            text="Convert AAC audio to PCM for DaVinci Resolve on Linux",
            font=("Courier New", 10),
            fg=FG_MUTED, bg=BG_DARK,
        ).pack()

        # Connection status
        status_bar = tk.Frame(self.root, bg=BG_MID, pady=6, padx=14)
        status_bar.pack(fill="x")

        if self.resolve:
            project = self.resolve.GetProjectManager().GetCurrentProject()
            proj_name = project.GetName() if project else "No project open"
            status_text  = f"Connected  |  Project: {proj_name}"
            status_color = FG_GREEN
        else:
            status_text  = "DaVinci Resolve not detected — run from Workspace → Scripts"
            status_color = FG_RED

        tk.Label(
            status_bar,
            text=status_text,
            font=("Courier New", 9),
            fg=status_color, bg=BG_MID,
            anchor="w",
        ).pack(fill="x")

        # Progress bar
        prog_frame = tk.Frame(self.root, bg=BG_MAIN, pady=10, padx=14)
        prog_frame.pack(fill="x")

        self.progress_var = tk.DoubleVar()
        ttk.Progressbar(
            prog_frame,
            variable=self.progress_var,
            maximum=100,
            length=472,
        ).pack(fill="x")

        self.status_label = tk.Label(
            prog_frame,
            text="Ready.",
            font=("Courier New", 9),
            fg=FG_MUTED, bg=BG_MAIN,
            anchor="w",
        )
        self.status_label.pack(fill="x", pady=(4, 0))

        # Log
        log_frame = tk.Frame(self.root, bg=BG_MAIN, padx=14)
        log_frame.pack(fill="both", expand=True)

        self.log = scrolledtext.ScrolledText(
            log_frame,
            height=12, width=62,
            font=("Courier New", 9),
            bg=BG_DARK, fg=FG_TEXT,
            insertbackground="white",
            state="disabled",
            relief="flat",
        )
        self.log.pack(fill="both", expand=True)

        # Buttons
        btn_frame = tk.Frame(self.root, bg=BG_MAIN, pady=12, padx=14)
        btn_frame.pack(fill="x")

        self.convert_btn = tk.Button(
            btn_frame,
            text="Convert AAC Clips in Current Folder",
            command=self._start_conversion,
            font=("Courier New", 10, "bold"),
            bg=BTN_GREEN, fg="white",
            activebackground="#2ea043",
            relief="flat", padx=12, pady=6,
            cursor="hand2",
        )
        self.convert_btn.pack(side="left")

        tk.Button(
            btn_frame,
            text="Close",
            command=self.root.destroy,
            font=("Courier New", 10),
            bg=BTN_GRAY, fg=FG_TEXT,
            activebackground="#30363d",
            relief="flat", padx=12, pady=6,
            cursor="hand2",
        ).pack(side="right")

        # Footer
        tk.Label(
            self.root,
            text="github.com/owlivion/resolve-audio-fix",
            font=("Courier New", 8),
            fg="#484f58", bg=BG_MAIN,
        ).pack(pady=(0, 6))

    # -----------------------------------------------------------------------
    # Internal helpers
    # -----------------------------------------------------------------------

    def _log(self, msg: str):
        self.log.configure(state="normal")
        self.log.insert("end", msg + "\n")
        self.log.see("end")
        self.log.configure(state="disabled")
        self.root.update_idletasks()

    def _set_status(self, msg: str):
        self.status_label.configure(text=msg)
        self.root.update_idletasks()

    def _start_conversion(self):
        if self.running:
            return
        self.progress_var.set(0)
        thread = threading.Thread(target=self._run_conversion, daemon=True)
        thread.start()

    def _run_conversion(self):
        self.running = True
        self.convert_btn.configure(state="disabled")
        try:
            self._convert()
        finally:
            self.running = False
            self.convert_btn.configure(state="normal")

    def _convert(self):
        if not self.resolve:
            self._log("ERROR: DaVinci Resolve not connected.")
            self._log("Run this script from Workspace → Scripts inside DaVinci Resolve.")
            return

        project = self.resolve.GetProjectManager().GetCurrentProject()
        if not project:
            self._log("ERROR: No project open in DaVinci Resolve.")
            return

        media_pool   = project.GetMediaPool()
        folder       = media_pool.GetCurrentFolder()
        clips        = folder.GetClipList() or []

        if not clips:
            self._log("No clips found in the current Media Pool folder.")
            return

        self._log(f"Scanning {len(clips)} clip(s)...")
        self._set_status("Scanning clips...")

        aac_clips = []
        for clip in clips:
            filepath = clip.GetClipProperty("File Path")
            if not filepath or not os.path.isfile(filepath):
                continue
            if get_audio_codec(filepath) == "aac":
                aac_clips.append((clip, filepath))

        if not aac_clips:
            self._log("✓ No AAC clips found. All clips are already compatible.")
            self._set_status("Nothing to convert.")
            self.progress_var.set(100)
            return

        self._log(f"Found {len(aac_clips)} AAC clip(s) to convert.\n")

        converted_paths = []
        for i, (clip, filepath) in enumerate(aac_clips, 1):
            name = clip.GetClipProperty("Clip Name") or os.path.basename(filepath)
            self._log(f"[{i}/{len(aac_clips)}] {name}")
            self._set_status(f"Converting {i}/{len(aac_clips)}: {name}")

            output = convert_to_pcm(filepath)
            if output:
                converted_paths.append(output)
                self._log(f"    → {os.path.basename(output)}")
            else:
                self._log("    ✗ Conversion failed.")

            self.progress_var.set((i / len(aac_clips)) * 100)

        if converted_paths:
            self._log(f"\nImporting {len(converted_paths)} file(s) into Media Pool...")
            media_pool.ImportMedia(converted_paths)
            self._log(f"✓ Done! {len(converted_paths)} clip(s) converted and imported.")
            self._set_status(f"Done. {len(converted_paths)} clip(s) converted.")
        else:
            self._log("✗ No clips were successfully converted. Check the log.")
            self._set_status("Conversion failed.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    resolve = _connect_resolve()

    root = tk.Tk()
    root.geometry("500x460")
    DrAudioFixApp(root, resolve)
    root.mainloop()


if __name__ == "__main__":
    main()
