---
name: Bug Report
about: A file wasn't converted, or the tool behaved unexpectedly
title: "[BUG] "
labels: bug
assignees: ''
---

## Description
A clear description of what went wrong.

## Steps to Reproduce
1. ...
2. ...

## Expected Behavior
What should have happened.

## Actual Behavior
What actually happened.

## File Info
Run this and paste the output:
```bash
ffprobe -v quiet -print_format json -show_streams /path/to/your/file
```

<details>
<summary>ffprobe output</summary>

```json
paste here
```
</details>

## Log Output
```bash
cat ~/.local/share/resolve-audio-fix/convert.log
```

<details>
<summary>Log</summary>

```
paste here
```
</details>

## Environment
- OS / Distro:
- DaVinci Resolve version:
- resolve-audio-fix version (or commit):
- Install method: `install.sh` / manual
