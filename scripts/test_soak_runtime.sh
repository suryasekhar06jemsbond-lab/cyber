#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

iterations="${1:-60}"

echo "[soak] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat > "$tmpd/soak.ny" <<'CYEOF'
fn fib(n) {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

let total = 0;
for (x in [1, 2, 3, 4, 5]) {
    total = total + fib(x);
}

let ys = [n * 2 for n in [1, 2, 3, 4, 5] if n > 2];
print(total + ys[0] + len(ys));
CYEOF

expected='21'

echo "[soak] iterations=$iterations"
for i in $(seq 1 "$iterations"); do
  out_ast=$(./nyx --max-steps 500000 "$tmpd/soak.ny")
  out_vm=$(./nyx --vm-strict --max-steps 500000 "$tmpd/soak.ny")

  if [ "$out_ast" != "$expected" ]; then
    echo "FAIL: AST soak output mismatch at iteration $i"
    echo "Expected: $expected"
    echo "Got: $out_ast"
    exit 1
  fi
  if [ "$out_vm" != "$expected" ]; then
    echo "FAIL: VM soak output mismatch at iteration $i"
    echo "Expected: $expected"
    echo "Got: $out_vm"
    exit 1
  fi
done

echo "[soak] PASS"
