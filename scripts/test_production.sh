#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[prod] building runtime..."
make >/dev/null

if [ -f ./build/nyx ]; then
  chmod +x ./build/nyx
fi
if [ -f ./nyx ]; then
  chmod +x ./nyx
fi

echo "[prod] release package sanity..."
./scripts/package_release.sh --target linux-x64 --binary ./build/nyx --out-dir ./dist >/dev/null
pkg_entries=$(tar -tzf ./dist/nyx-linux-x64.tar.gz)
for required in \
  "./nyx" \
  "./scripts/nypm.sh" \
  "./scripts/nyfmt.sh" \
  "./scripts/nylint.sh" \
  "./scripts/nydbg.sh" \
  "./stdlib/types.ny" \
  "./compiler/bootstrap.ny" \
  "./examples/fibonacci.ny"; do
  echo "$pkg_entries" | grep -Fx "$required" >/dev/null || {
    echo "[prod] FAIL: missing release payload file $required" >&2
    exit 1
  }
done

echo "[prod] core test suite..."
./scripts/test_v0.sh
./scripts/test_v1.sh
./scripts/test_v2.sh
./scripts/test_v3_start.sh
./scripts/test_v4.sh
./scripts/test_compatibility.sh
./scripts/test_ecosystem.sh
./scripts/test_registry.sh
./scripts/test_runtime_hardening.sh
./scripts/test_sanitizers.sh

echo "[prod] vm consistency..."
./scripts/test_vm_consistency.sh 1337 300
./scripts/test_fuzz_vm.sh 4242 500
./scripts/test_soak_runtime.sh 40

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
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_registry.ps1
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_runtime_hardening.ps1
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_sanitizers.ps1
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_fuzz_vm.ps1 -Seed 4242 -Cases 500
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/test_soak_runtime.ps1 -Iterations 40

  echo "[prod] powershell tooling smoke..."
  tmpd=$(mktemp -d)
  trap 'rm -rf "$tmpd"' EXIT

  printf 'let x = 1;\nprint(x);\n' > "$tmpd/min.ny"
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/nyfmt.ps1 "$tmpd/min.ny" >/dev/null
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/nyfmt.ps1 -Check "$tmpd/min.ny" >/dev/null
  "$pwsh_bin" -NoLogo -NoProfile -File ./scripts/nydbg.ps1 "$tmpd/min.ny" >/dev/null 2>&1

  (
    cd "$tmpd"
    mkdir -p core app
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" init demo >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" add core ./core 1.2.3 >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" add app ./app 0.1.0 core@^1.0.0 >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" resolve app >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" lock app >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" verify-lock >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" install app ./.nydeps >/dev/null
    "$pwsh_bin" -NoLogo -NoProfile -File "$ROOT_DIR/scripts/nypm.ps1" doctor >/dev/null
  )
fi

echo "[prod] PASS"
