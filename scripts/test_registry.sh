#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

mkdir -p "$tmpd/pkgs/core" "$tmpd/pkgs/util" "$tmpd/pkgs/app"
printf 'module Core { let v = 1; }\n' > "$tmpd/pkgs/core/core.nx"
printf 'module Util { let v = 2; }\n' > "$tmpd/pkgs/util/util.nx"
printf 'module App { let v = 3; }\n' > "$tmpd/pkgs/app/app.nx"

cat > "$tmpd/cy.registry" <<REGEOF
# name|version|source|deps
core|1.0.0|./pkgs/core|
core|1.2.0|./pkgs/core|
util|2.1.0|./pkgs/util|core@^1.0.0
REGEOF

(
  cd "$tmpd"
  "$ROOT_DIR/scripts/cypm.sh" init demo >/dev/null
  "$ROOT_DIR/scripts/cypm.sh" registry set "$tmpd/cy.registry" >/dev/null

  search_out=$("$ROOT_DIR/scripts/cypm.sh" search core)
  echo "$search_out" | grep -F "core version=1.2.0" >/dev/null || {
    echo "FAIL: cypm search missing expected registry entry"
    echo "$search_out"
    exit 1
  }

  "$ROOT_DIR/scripts/cypm.sh" add-remote core ^1.0.0 >/dev/null
  list_out=$("$ROOT_DIR/scripts/cypm.sh" list)
  echo "$list_out" | grep -F "core=$tmpd/./pkgs/core version=1.2.0" >/dev/null || {
    echo "FAIL: cypm add-remote did not choose highest matching core version"
    echo "$list_out"
    exit 1
  }

  "$ROOT_DIR/scripts/cypm.sh" add-remote util ">=2.0.0" >/dev/null
  resolved=$("$ROOT_DIR/scripts/cypm.sh" resolve util)
  expected='core
util'
  [ "$resolved" = "$expected" ] || {
    echo "FAIL: cypm resolve from registry dependencies mismatch"
    echo "Expected:"
    printf '%s\n' "$expected"
    echo "Got:"
    printf '%s\n' "$resolved"
    exit 1
  }

  "$ROOT_DIR/scripts/cypm.sh" install util ./.cydeps >/dev/null
  [ -d "$tmpd/.cydeps/core" ] || {
    echo "FAIL: cypm install missing core dependency dir"
    exit 1
  }
  [ -d "$tmpd/.cydeps/util" ] || {
    echo "FAIL: cypm install missing util dependency dir"
    exit 1
  }

  "$ROOT_DIR/scripts/cypm.sh" publish app 0.1.0 "$tmpd/pkgs/app" "util@>=2.0.0" >/dev/null
  "$ROOT_DIR/scripts/cypm.sh" add-remote app 0.1.0 >/dev/null
  list_out2=$("$ROOT_DIR/scripts/cypm.sh" list)
  echo "$list_out2" | grep -F "app=$tmpd/pkgs/app version=0.1.0 deps=util@>=2.0.0" >/dev/null || {
    echo "FAIL: cypm publish/add-remote app failed"
    echo "$list_out2"
    exit 1
  }
)

echo "[registry] PASS"
