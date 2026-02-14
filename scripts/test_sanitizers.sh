#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

os=$(uname -s 2>/dev/null || echo unknown)
case "$os" in
  Linux|Darwin) ;;
  *)
    echo "[san] skip: sanitizers are only enforced on Linux/macOS (detected: $os)"
    exit 0
    ;;
esac

pick_compiler() {
  if command -v clang >/dev/null 2>&1; then
    command -v clang
    return 0
  fi
  if command -v gcc >/dev/null 2>&1; then
    command -v gcc
    return 0
  fi
  return 1
}

if ! cc_bin="$(pick_compiler)"; then
  echo "[san] skip: no clang/gcc found"
  exit 0
fi

echo "[san] compiler: $cc_bin"

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat >"$tmpd/probe.c" <<'EOF'
int main(void) { return 0; }
EOF

SAN_FLAGS="-O1 -g -std=c99 -Wall -Wextra -Werror -fno-omit-frame-pointer -fsanitize=address,undefined"
if ! "$cc_bin" $SAN_FLAGS -o "$tmpd/probe" "$tmpd/probe.c" >/dev/null 2>&1; then
  echo "[san] skip: compiler does not support address+undefined sanitizers"
  exit 0
fi

echo "[san] building sanitized runtime..."
"$cc_bin" $SAN_FLAGS -o "$tmpd/cy_san" native/nyx.c

cat >"$tmpd/smoke.ny" <<'CYEOF'
fn add(a, b) {
    return a + b;
}

module M {
    fn id(x) {
        return x;
    }
}

class Box {
    fn init(self, v) {
        object_set(self, "v", v);
    }
    fn get(self) {
        return object_get(self, "v");
    }
}

let b = new(Box, 40);
let xs = [n + 1 for n in [1, 2, 3, 4] if n > 1];
print(add(M.id(b.get()), xs[0]));
CYEOF

cat >"$tmpd/limits.ny" <<'CYEOF'
let i = 0;
while (true) {
    i = i + 1;
}
CYEOF

export ASAN_OPTIONS="${ASAN_OPTIONS:-detect_leaks=1:abort_on_error=1}"
export UBSAN_OPTIONS="${UBSAN_OPTIONS:-print_stacktrace=1:halt_on_error=1}"

out_ast=$("$tmpd/cy_san" "$tmpd/smoke.ny")
out_vm=$("$tmpd/cy_san" --vm-strict "$tmpd/smoke.ny")
[ "$out_ast" = "$out_vm" ] || {
  echo "FAIL: sanitized AST/VM mismatch"
  echo "AST: $out_ast"
  echo "VM:  $out_vm"
  exit 1
}

if "$tmpd/cy_san" --max-steps 120 "$tmpd/limits.ny" >/dev/null 2>"$tmpd/limit.err"; then
  echo "FAIL: sanitized max-steps limit expected failure"
  exit 1
fi
grep -q "max step count exceeded" "$tmpd/limit.err" || {
  echo "FAIL: sanitized limit error message missing"
  cat "$tmpd/limit.err"
  exit 1
}

echo "[san] PASS"
