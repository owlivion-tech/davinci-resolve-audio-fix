# Contributing to resolve-audio-fix

Thank you for your interest in contributing! This project exists to solve a real pain point for DaVinci Resolve users on Linux, and every contribution helps.

## Ways to Contribute

- **Bug reports** — a file format that isn't handled, a conversion that fails
- **Feature requests** — new file manager integrations (Thunar, Dolphin, Nemo), distro support
- **Pull requests** — fixes, improvements, new features
- **Documentation** — better explanations, translations, usage examples
- **Testing** — test on different distros and report compatibility

## Reporting a Bug

Before opening an issue, please run:

```bash
ffprobe -v quiet -print_format json -show_streams /path/to/your/file.ext
```

Include the output in your bug report. This helps identify codec issues immediately.

Use the **Bug Report** issue template and fill in all sections.

## Pull Request Guidelines

1. **Fork** the repository and create a branch from `main`
2. Keep changes **focused** — one fix or feature per PR
3. Test your changes before submitting
4. Update the README if you add a new feature or change behavior
5. Follow the existing code style:
   - `set -euo pipefail` at the top of all scripts
   - Variables in double quotes: `"$VAR"`
   - Functions for repeated logic
   - Comments in English

## Adding File Manager Support

To add support for a new file manager (e.g., Thunar, Dolphin):

1. Create a script in a new directory: `<file-manager>/DR Audio Fix`
2. Check how that file manager passes selected files (env var or stdin)
3. Call `dr-convert.sh` for each selected file
4. Update `install.sh` to detect and install the script
5. Document in README under **Usage**

## Code Style

```bash
#!/bin/bash
set -euo pipefail

# Functions are lowercase_snake_case
convert_file() {
    local input="$1"
    # ...
}

# Constants are UPPER_CASE
OUTPUT_FORMAT="mov"
```

## Testing

Before submitting a PR, test:

- [ ] `dr-convert.sh` on a file with AAC audio → should convert
- [ ] `dr-convert.sh` on a file with PCM/Opus/other audio → should skip
- [ ] `dr-convert.sh` on a non-video file → should skip
- [ ] `dr-convert.sh` on an already converted file (`_dr` suffix) → should skip
- [ ] `install.sh` on a fresh system (or Docker container)
- [ ] Systemd service starts and watches correctly

## Questions

Open a [Discussion](https://github.com/owlivion-tech/davinci-resolve-audio-fix/discussions) for questions that aren't bug reports or feature requests.
