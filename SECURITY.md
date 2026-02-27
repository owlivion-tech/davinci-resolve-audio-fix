# Security Policy

## Our Commitment

`resolve-audio-fix` is designed with a minimal and auditable attack surface:

| Property | Detail |
|----------|--------|
| **No network access** | Zero outbound calls. The tool only invokes `ffmpeg` and `ffprobe` locally. |
| **No root / sudo required** | Installs entirely to `~/.local/` and `~/.config/` (user space). |
| **No binary blobs** | Pure Bash + Python. Every line is human-readable. |
| **No data collection** | No telemetry, no analytics, no logging to external services. |
| **No eval / obfuscation** | All scripts pass ShellCheck and Bandit with zero warnings. |

These claims are automatically verified on every commit via GitHub Actions CI.

---

## Verify Before Installing

**1. Audit the code yourself:**
```bash
git clone https://github.com/owlivion-tech/davinci-resolve-audio-fix.git
cd resolve-audio-fix
bash verify.sh
```

**2. Preview the install without making changes:**
```bash
bash install.sh --dry-run
```

**3. Verify with strace (Linux):**
```bash
strace -e trace=network bash install.sh 2>&1 | grep -v "^---"
# Expected: no network syscalls
```

**4. Verify a signed release:**
```bash
# Import the maintainer's public key
gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>

# Verify the signature
gpg --verify checksums.sha256.sig checksums.sha256

# Check file integrity
sha256sum -c checksums.sha256
```

The maintainer's GPG key ID is published in the README and on the releases page.

---

## Supported Versions

Only the latest release on the `main` branch is actively maintained.
Older releases may contain unfixed issues — always use the latest version.

---

## Reporting a Vulnerability

If you discover a security issue, please **do not open a public GitHub issue**.

Instead:
1. Open a [GitHub Security Advisory](https://github.com/owlivion-tech/davinci-resolve-audio-fix/security/advisories/new) (private by default)
2. Describe the issue clearly and include steps to reproduce
3. Allow up to **7 days** for an initial response

Even though the attack surface of this tool is intentionally minimal, all reports are taken seriously. Thank you for helping keep this project trustworthy.
