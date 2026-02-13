#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[prod] building runtime..."
make >/dev/null

echo "[prod] core test suite..."
./scripts/test_v0.sh
./scripts/test_v1.sh
./scripts/test_v2.sh
./scripts/test_v3_start.sh
./scripts/test_v4.sh
./scripts/test_compatibility.sh
./scripts/test_ecosystem.sh

echo "[prod] vm consistency..."
./scripts/test_vm_consistency.sh 1337 300

resolve_pwsh() {
  if [ -n "${PWSH_BIN:-}" ] && [ -x "${PWSH_BIN}" ]; then
    echo "$PWSH_BIN"
    return 0
  fi
  if command -v pwsh >/dev/null 2>&1; then
    command -v pwsh
    return 0
  fi
  return 1
}

if pwsh_bin="$(resolve_pwsh)"; then
  echo "[prod] powershell suite..."
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_v3.ps1
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_v4.ps1
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_compatibility.ps1

  echo "[prod] powershell tooling smoke..."
  tmpd=$(mktemp -d)
  trap 'rm -rf "$tmpd"' EXIT

  printf 'let x = 1;\nprint(x);\n' > "$tmpd/min.cy"
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/cyfmt.ps1 "$tmpd/min.cy" >/dev/null
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/cydbg.ps1 "$tmpd/min.cy" >/dev/null 2>&1

  (
    cd "$tmpd"
    mkdir -p core app
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" init demo >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" add core ./core 1.2.3 >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" add app ./app 0.1.0 core@^1.0.0 >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" resolve app >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" lock app >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/cypm.ps1" verify-lock >/dev/null
  )
fi

echo "[prod] PASS"
