# Nyx Publish Guide

This guide covers formal binary releases and VS Code extension distribution.

## 1. Release Requirements

Before tagging a release:

1. Run `./scripts/test_production.sh` on Linux/macOS.
2. Run `./scripts/test_production.ps1 -VmCases 300` on Windows.
3. Confirm version output (`nyx --version`) matches intended release version policy.

## 2. Tag And Publish

1. Create and push a tag:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

2. Workflow `.github/workflows/release.yml` runs automatically and publishes a GitHub Release.
   Runtime version in built binaries is injected from tag (`vX.Y.Z` -> `X.Y.Z`).

Published assets:

- `nyx-linux-x64.tar.gz`
- `nyx-windows-x64.zip`
- `nyx-language.vsix`
- `*.sha256` checksum files

## 3. Install From Releases

Linux/macOS quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.sh | sh
```

Windows quick install:

```powershell
irm https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.ps1 | iex
```

Notes:
- One-line unauthenticated install requires the repo to be public.
- Install scripts are idempotent: if the installed checksum matches the release checksum, download is skipped.
- Support files (`nypm`, `nyfmt`, `nylint`, `nydbg`, stdlib/compiler/examples) are installed with the runtime.

Pin a specific version:

- Linux/macOS: `NYX_VERSION=vX.Y.Z`
- Windows: `-Version vX.Y.Z`

## 4. VS Code Distribution

Option A: release asset (`nyx-language.vsix`)

1. Open VS Code command palette.
2. Run `Extensions: Install from VSIX...`.
3. Select `nyx-language.vsix`.

Windows one-command install from release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_vscode.ps1 -Version vX.Y.Z
```

Option B: publish to VS Code Marketplace

1. Create publisher (`suryasekhar06jemsbond-lab`).
2. From `editor/vscode/nyx-language`:

```bash
npm install
npx @vscode/vsce publish
```

3. For CI-based publish, configure secret `VSCE_PAT`. Workflow `.github/workflows/vscode_publish.yml` publishes on release (or manual dispatch) when this secret is present.
