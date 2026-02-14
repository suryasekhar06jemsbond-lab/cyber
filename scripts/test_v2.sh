#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v2] building native runtime..."
make >/dev/null

if [ -f ./build/nyx ]; then
  chmod +x ./build/nyx
fi
if [ -f ./nyx ]; then
  chmod +x ./nyx
fi

if [ -x ./build/nyx ]; then
  runtime=./build/nyx
elif [ -x ./nyx ]; then
  runtime=./nyx
elif [ -x ./nyx.exe ]; then
  runtime=./nyx.exe
else
  echo "FAIL: runtime not found" >&2
  exit 1
fi

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat > "$tmpd/input.ny" << 'NYEOF'
40 + 2;
NYEOF

echo "[v2] compiling Nyx source with compiler/bootstrap.ny..."
"$runtime" compiler/bootstrap.ny "$tmpd/input.ny" "$tmpd/output.c" >/dev/null

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
