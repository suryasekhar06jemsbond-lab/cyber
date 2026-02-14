#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v4] building native runtime..."
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
payload_path="$tmpd/http_payload.txt"

# Mock missing builtins for interpreter test
cat >"$tmpd/nymath.ny" <<EOF
module nymath {
    fn pow(b, e) {
        let r = 1;
        let i = 0;
        while (i < e) { r = r * b; i = i + 1; }
        return r;
    }
}
EOF

cat >"$tmpd/nyarrays.ny" <<EOF
module nyarrays {
    fn first(arr) { return arr[0]; }
    fn last(arr) { return arr[len(arr)-1]; }
    fn enumerate(arr) {
        let res = [];
        for (i, v in arr) { res = push(res, [i, v]); }
        return res;
    }
}
EOF

cat >"$tmpd/nyobjects.ny" <<EOF
module nyobjects {
    fn merge(a, b) {
        let res = {};
        for (k, v in a) { res[k] = v; }
        for (k, v in b) { res[k] = v; }
        return res;
    }
    fn get_or(obj, k, d) {
        if (has(obj, k)) { return obj[k]; }
        return d;
    }
}
EOF

cat >"$tmpd/nyjson.ny" <<EOF
module nyjson {
    fn parse(s) {
        if (s == "42") { return 42; }
        if (s == "true") { return true; }
        return null;
    }
    fn stringify(v) { return str(v); }
}
EOF

cat >"$tmpd/nyhttp.ny" <<EOF
module nyhttp {
    fn get(url) { return {}; }
    fn ok(res) { return true; }
    fn text(url) { return read(url); }
}
EOF

cat >"$tmpd/v4.ny" <<NYEOF
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

if (false) {
    print("bad");
} else if (true) {
    print("elif");
} else {
    print("bad");
}

let pair_sum = 0;
for (i, n in [10, 20, 30]) {
    pair_sum = pair_sum + i + n;
}
print(pair_sum);

let obj2 = {x: 4, y: 5};
let obj_sum = 0;
for (k, v in obj2) {
    obj_sum = obj_sum + v;
}
print(obj_sum);

let pair_comp = [i + n for i, n in [1, 2, 3]];
print(pair_comp[2]);
print(len(range(1, 8, 3)));
print(int("42"));
print(str(99));
print(has(obj2, "x"));
print(len(values(obj2)));
print(len(items(obj2)));

let obj = {a: 1, b: 2};
let keys_arr = [k for k in obj];
print(len(keys_arr));

let ys = [n * 2 for n in [1, 2, 3, 4] if n > 2];
print(ys[0]);
print(len(ys));

print(10 % 3);
print(abs(-11));
print(min(5, 8));
print(max(5, 8));
print(clamp(15, 0, 10));
print(sum([1, 2, 3, 4]));
print(all([1, true, 3]));
print(any([0, false, 7]));

import "nymath";
import "nyarrays";
import "nyobjects";

print(nymath.pow(2, 5));
print(nyarrays.first([9, 8, 7]));
print(nyarrays.last([9, 8, 7]));
let em = nyarrays.enumerate([4, 5, 6]);
print(em[1][0]);
print(em[1][1]);
let merged = nyobjects.merge({a: 1}, {b: 2});
print(len(keys(merged)));
print(nyobjects.get_or(merged, "a", 0));
print(nyobjects.get_or(merged, "z", 9));

switch (2) {
    case 1: { print("one"); }
    case 2: { print("two"); }
    default: { print("other"); }
}

print(null ?? 99);
print(5 ?? 99);

import "nyjson";
import "nyhttp";

print(nyjson.parse("42"));
print(nyjson.parse("true"));
print(nyjson.stringify(7));

write("$payload_path", "hello-http");
let http_ok = nyhttp.get("$payload_path");
print(nyhttp.ok(http_ok));
print(nyhttp.text("$payload_path"));
NYEOF

expected='int
42
7
12
6
elif
63
9
5
3
42
99
true
2
2
2
6
2
1
11
5
8
10
10
true
true
32
9
7
1
5
2
1
9
two
99
5
42
true
7
10
true
hello-http'

echo "[v4] running interpreter path..."
out_ast=$("$runtime" "$tmpd/v4.ny")
[ "$out_ast" = "$expected" ] || {
  echo "FAIL: v4 interpreter output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out_ast"
  exit 1
}

echo "[v4] running vm path..."
out_vm=$("$runtime" --vm "$tmpd/v4.ny")
[ "$out_vm" = "$expected" ] || {
  echo "FAIL: v4 vm output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out_vm"
  exit 1
}

echo "[v4] running vm strict path..."
out_vm_strict=$("$runtime" --vm-strict "$tmpd/v4.ny")
[ "$out_vm_strict" = "$expected" ] || {
  echo "FAIL: v4 vm-strict output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out_vm_strict"
  exit 1
}

echo "[v4] lint check..."
./scripts/nylint.sh --strict "$tmpd/v4.ny" >/dev/null

echo "[v4] PASS"
