#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v3] building native runtime..."
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

# 1) Compile compiler source with compiler output path.
echo "[v3] compiling compiler source with output path..."
"$runtime" compiler/v3_seed.ny compiler/v3_seed.ny "$tmpd/compiler_stage1.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/compiler_stage1" "$tmpd/compiler_stage1.c"

# 2) Compile and run a richer Nyx program:
# import, fn/return, arrays/index, calls, if, while/for, class/module/typealias,
# member/index assignment, and v4 compatibility builtins.
cat > "$tmpd/lib.ny" <<'NYEOF'
fn add(a, b) {
    return a + b;
}

fn inc(self, n) {
    return self.x + n;
}

fn point_ctor(self, x, y) {
    object_set(self, "x", x);
    object_set(self, "y", y);
    return null;
}
NYEOF

cat > "$tmpd/program.ny" <<NYEOF
import "$tmpd/lib.ny";

require_version(lang_version());
typealias IntType = "int";
print(IntType);

module Math {
    fn add2(a, b) {
        return a + b;
    }
    let tag = "math";
}
print(Math.add2(40, 2));
print(Math.tag);

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
p.y = 9;
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

let obj = {x: 40, inc: inc};
obj["y"] = 2;
print(obj.inc(obj["y"]));
print(len(keys(obj)));
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
if (true && true) {
    print("and");
}
if (false || true) {
    print("or");
}

try {
    throw "boom";
} catch (e) {
    print(e);
}
NYEOF

echo "[v3] compiling rich program with rebuilt compiler..."
"$tmpd/compiler_stage1" "$tmpd/program.ny" "$tmpd/program.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/program_bin" "$tmpd/program.c"
out_prog=$("$tmpd/program_bin")
expected_prog='int
42
math
7
12
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
42
3
3
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
and
or
boom'
if [ "$out_prog" != "$expected_prog" ]; then
  echo "FAIL: compiled rich program output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected_prog"
  echo "Got:"
  printf '%s\n' "$out_prog"
  exit 1
fi

# 3) Rebuild-and-compare deterministic loop.
# stage1 binary compiles compiler source -> stage2.c (self mode)
"$tmpd/compiler_stage1" compiler/v3_seed.ny "$tmpd/compiler_stage2.c" --emit-self >/dev/null

if ! cmp -s "$tmpd/compiler_stage1.c" "$tmpd/compiler_stage2.c"; then
  echo "FAIL: stage1.c and stage2.c differ"
  echo "--- stage1.c"
  cat "$tmpd/compiler_stage1.c"
  echo "--- stage2.c"
  cat "$tmpd/compiler_stage2.c"
  exit 1
fi

cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/compiler_stage2" "$tmpd/compiler_stage2.c"

# stage2 binary compiles compiler source -> stage3.c (self mode)
"$tmpd/compiler_stage2" compiler/v3_seed.ny "$tmpd/compiler_stage3.c" --emit-self >/dev/null

if ! cmp -s "$tmpd/compiler_stage2.c" "$tmpd/compiler_stage3.c"; then
  echo "FAIL: stage2.c and stage3.c differ"
  echo "--- stage2.c"
  cat "$tmpd/compiler_stage2.c"
  echo "--- stage3.c"
  cat "$tmpd/compiler_stage3.c"
  exit 1
fi

# Sanity check: rebuilt compiler still compiles rich source correctly.
"$tmpd/compiler_stage2" "$tmpd/program.ny" "$tmpd/program_from_stage2.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/program_from_stage2_bin" "$tmpd/program_from_stage2.c"
out_prog_stage2=$("$tmpd/program_from_stage2_bin")
if [ "$out_prog_stage2" != "$expected_prog" ]; then
  echo "FAIL: rebuilt compiler could not compile rich source correctly"
  echo "Expected:"
  printf '%s\n' "$expected_prog"
  echo "Got:"
  printf '%s\n' "$out_prog_stage2"
  exit 1
fi

echo "[v3] PASS"
