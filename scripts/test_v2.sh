#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v2] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat > "$tmpd/input.nx" << 'CYEOF'
40 + 2;
CYEOF

echo "[v2] compiling Cy source with compiler/bootstrap.nx..."
./nyx compiler/bootstrap.nx "$tmpd/input.nx" "$tmpd/output.c" >/dev/null

[ -f "$tmpd/output.c" ] || {
  echo "FAIL: compiler did not produce output.c"
  exit 1
}

echo "[v2] compiling generated C..."
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/output_bin" "$tmpd/output.c"

echo "[v2] executing generated binary..."
out=$("$tmpd/output_bin")
expected='42'

if [ "$out" != "$expected" ]; then
  echo "FAIL: unexpected output from compiled program"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out"
  exit 1
fi

echo "[v2] PASS"
