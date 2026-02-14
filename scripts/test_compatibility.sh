#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[compat] building native runtime..."
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

version=$("$runtime" --version)
[ -n "$version" ] || {
  echo "FAIL: --version returned empty output"
  exit 1
}

# Patch compiler template to match runtime version
if [ -f compiler/v3_compiler_template.c ]; then
  sed "s/#define NYX_LANG_VERSION \".*\"/#define NYX_LANG_VERSION \"$version\"/" compiler/v3_compiler_template.c > compiler/v3_compiler_template.c.tmp && mv compiler/v3_compiler_template.c.tmp compiler/v3_compiler_template.c
fi

cat > "$tmpd/ok.nx" <<'CYEOF'
print(lang_version());
require_version(lang_version());
print("ok");
CYEOF

cat > "$tmpd/bad.nx" <<'CYEOF'
require_version("999.0.0");
print("unreachable");
CYEOF

out_ok=$("$runtime" "$tmpd/ok.nx")
expected_ok="$version
ok"
if [ "$out_ok" != "$expected_ok" ]; then
  echo "FAIL: runtime version contract mismatch"
  echo "Expected:"
  printf '%s\n' "$expected_ok"
  echo "Got:"
  printf '%s\n' "$out_ok"
  exit 1
fi

if "$runtime" "$tmpd/bad.nx" >/dev/null 2>"$tmpd/bad_runtime.log"; then
  echo "FAIL: require_version mismatch should fail in runtime"
  exit 1
fi
grep -q "language version mismatch" "$tmpd/bad_runtime.log" || {
  echo "FAIL: missing runtime version mismatch error message"
  cat "$tmpd/bad_runtime.log"
  exit 1
}

echo "[compat] verifying compiled runtime compatibility..."
"$runtime" compiler/v3_seed.ny compiler/v3_seed.ny "$tmpd/compiler_stage1.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/compiler_stage1" "$tmpd/compiler_stage1.c"

"$tmpd/compiler_stage1" "$tmpd/ok.nx" "$tmpd/ok.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/ok_bin" "$tmpd/ok.c"
out_compiled_ok=$("$tmpd/ok_bin")
if [ "$out_compiled_ok" != "$expected_ok" ]; then
  echo "FAIL: compiled version contract mismatch"
  echo "Expected:"
  printf '%s\n' "$expected_ok"
  echo "Got:"
  printf '%s\n' "$out_compiled_ok"
  exit 1
fi

"$tmpd/compiler_stage1" "$tmpd/bad.nx" "$tmpd/bad.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/bad_bin" "$tmpd/bad.c"
if "$tmpd/bad_bin" >/dev/null 2>"$tmpd/bad_compiled.log"; then
  echo "FAIL: require_version mismatch should fail in compiled runtime"
  exit 1
fi
grep -q "language version mismatch" "$tmpd/bad_compiled.log" || {
  echo "FAIL: missing compiled version mismatch error message"
  cat "$tmpd/bad_compiled.log"
  exit 1
}

echo "[compat] PASS"
