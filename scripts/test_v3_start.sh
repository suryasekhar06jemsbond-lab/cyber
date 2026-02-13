#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v3] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

# 1) Compile compiler source with compiler output path.
echo "[v3] compiling compiler source with output path..."
./cy compiler/v3_seed.cy compiler/v3_seed.cy "$tmpd/compiler_stage1.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/compiler_stage1" "$tmpd/compiler_stage1.c"

# 2) Compile and run a richer Cy program:
# import, fn/return, arrays/index, calls, if, while/for, class/module/typealias,
# member/index assignment, and v4 compatibility builtins.
cat > "$tmpd/lib.cy" <<'CYEOF'
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
CYEOF

cat > "$tmpd/program.cy" <<CYEOF
import "$tmpd/lib.cy";

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

let obj = {x: 40, inc: inc};
obj["y"] = 2;
print(obj.inc(obj["y"]));
print(len(keys(obj)));

try {
    throw "boom";
} catch (e) {
    print(e);
}
CYEOF

echo "[v3] compiling rich program with rebuilt compiler..."
"$tmpd/compiler_stage1" "$tmpd/program.cy" "$tmpd/program.c" >/dev/null
cc -O2 -std=c99 -Wall -Wextra -Werror -o "$tmpd/program_bin" "$tmpd/program.c"
out_prog=$("$tmpd/program_bin")
expected_prog='int
42
math
7
12
12
6
42
3
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
"$tmpd/compiler_stage1" compiler/v3_seed.cy "$tmpd/compiler_stage2.c" --emit-self >/dev/null

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
"$tmpd/compiler_stage2" compiler/v3_seed.cy "$tmpd/compiler_stage3.c" --emit-self >/dev/null

if ! cmp -s "$tmpd/compiler_stage2.c" "$tmpd/compiler_stage3.c"; then
  echo "FAIL: stage2.c and stage3.c differ"
  echo "--- stage2.c"
  cat "$tmpd/compiler_stage2.c"
  echo "--- stage3.c"
  cat "$tmpd/compiler_stage3.c"
  exit 1
fi

# Sanity check: rebuilt compiler still compiles rich source correctly.
"$tmpd/compiler_stage2" "$tmpd/program.cy" "$tmpd/program_from_stage2.c" >/dev/null
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
