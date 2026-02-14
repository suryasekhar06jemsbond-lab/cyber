#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v1] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat > "$tmpd/lib.ny" << 'NYEOF'
fn add(a, b) {
    return a + b;
}

let base = 10;
NYEOF

cat > "$tmpd/main.ny" << 'NYEOF'
import "lib.ny";

let x = add(base, 5);
if (x > 10) {
    print("ok");
} else {
    print("bad");
}

let arr = [1, 2, 3];
print(len(arr));
print(arr[1]);
print("hi" + "!");
write("out.txt", "hello");
print(read("out.txt"));
1 + 2;
NYEOF

echo "[v1] running scenario..."
out=$(./nyx "$tmpd/main.ny")
expected='ok
3
2
hi!
5
hello
3'

if [ "$out" != "$expected" ]; then
  echo "FAIL: unexpected output"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out"
  exit 1
fi

echo "[v1] PASS"
