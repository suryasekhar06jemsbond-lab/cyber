#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v4] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat >"$tmpd/v4.cy" <<'CYEOF'
require_version(lang_version());

typealias IntType = "int";
print(IntType);

module Math {
    fn add(a, b) {
        return a + b;
    }
    let tag = "math";
}

print(Math.add(40, 2));

class Point {
    fn init(self, x, y) {
        object_set(self, "x", x);
        object_set(self, "y", y);
    }

    fn sum(self) {
        return object_get(self, "x") + object_get(self, "y");
    }
}

let p = new(Point, 3, 4);
print(p.sum());

let i = 0;
let acc = 0;
while (i < 5) {
    i = i + 1;
    if (i == 3) {
        continue;
    }
    acc = acc + i;
}
print(acc);

let total = 0;
for (n in [1, 2, 3]) {
    total = total + n;
}
print(total);

let obj = {a: 1, b: 2};
let keys_arr = [k for k in obj];
print(len(keys_arr));

let ys = [n * 2 for n in [1, 2, 3, 4] if n > 2];
print(ys[0]);
print(len(ys));
CYEOF

expected='int
42
7
12
6
2
6
2'

echo "[v4] running interpreter path..."
out_ast=$(./cy "$tmpd/v4.cy")
[ "$out_ast" = "$expected" ] || {
  echo "FAIL: v4 interpreter output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out_ast"
  exit 1
}

echo "[v4] running vm path..."
out_vm=$(./cy --vm "$tmpd/v4.cy")
[ "$out_vm" = "$expected" ] || {
  echo "FAIL: v4 vm output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out_vm"
  exit 1
}

echo "[v4] lint check..."
./scripts/cylint.sh "$tmpd/v4.cy" >/dev/null

echo "[v4] PASS"
