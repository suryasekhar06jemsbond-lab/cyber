#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

seed="${1:-5150}"
cases="${2:-120}"

echo "[vm-prog-consistency] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

RANDOM="$seed"
echo "[vm-prog-consistency] seed=$seed cases=$cases"

for i in $(seq 1 "$cases"); do
  n=$((RANDOM % 6 + 3))
  skip=$((RANDOM % n + 1))
  offset=$((RANDOM % 5 - 2))
  threshold=$((RANDOM % 3 + 1))
  factor=$((RANDOM % 4 + 1))

  file="$tmpd/case_$i.ny"
  cat >"$file" <<CYEOF
fn mul(a, b) {
    return a * b;
}

module Math {
    fn inc(x) {
        return x + 1;
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

let acc = 0;
let i = 0;
while (i < $n) {
    i = i + 1;
    if (i == $skip) {
        continue;
    }
    acc = acc + i;
}

let arr = [x + $offset for x in [1, 2, 3, 4, 5] if x > $threshold];
let sum = 0;
for (v in arr) {
    sum = sum + v;
}

try {
    if (sum > 0) {
        throw "boom";
    }
} catch (e) {
    acc = acc + 1;
}

let b = new(Box, acc);
print(mul(Math.inc(b.get()), $factor) + sum + len(arr));
CYEOF

  if ! out_ast=$(./nyx "$file" 2>&1); then
    echo "FAIL: AST run failed on case $i"
    cat "$file"
    printf '%s\n' "$out_ast"
    exit 1
  fi

  if ! out_vm=$(./nyx --vm-strict "$file" 2>&1); then
    echo "FAIL: VM strict run failed on case $i"
    cat "$file"
    printf '%s\n' "$out_vm"
    exit 1
  fi

  if [ "$out_ast" != "$out_vm" ]; then
    echo "FAIL: AST/VM strict mismatch on case $i"
    cat "$file"
    echo "AST: $out_ast"
    echo "VM:  $out_vm"
    exit 1
  fi
done

echo "[vm-prog-consistency] PASS"
