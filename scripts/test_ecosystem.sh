#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[eco] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat > "$tmpd/ecosystem.ny" <<EOCY
import "$ROOT_DIR/stdlib/types.ny";
import "$ROOT_DIR/stdlib/class.ny";

let arr = [];
arr = push(arr, 10);
arr = push(arr, 20);
print(len(arr));
print(pop(arr));
print(len(arr));
print(type(arr));
print(is_int(7));

fn point_ctor(self, x, y) {
    object_set(self, "x", x);
    object_set(self, "y", y);
}

let Point = class_with_ctor("Point", point_ctor);
let p = class_instantiate2(Point, 3, 4);
print(class_name(Point));
print(object_get(p, "x"));
print(object_get(p, "y"));
EOCY

out=$(./nyx "$tmpd/ecosystem.ny")
expected='2
20
1
array
true
Point
3
4'
if [ "$out" != "$expected" ]; then
  echo "FAIL: ecosystem output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out"
  exit 1
fi

cat > "$tmpd/min.ny" <<'EOCY'
1 + 2;
EOCY

trace=$(./scripts/nydbg.sh --break 1 --step-count 1 "$tmpd/min.ny" 2>&1)
echo "$trace" | grep -F "[break]" >/dev/null || {
  echo "FAIL: nydbg breakpoint output missing"
  echo "$trace"
  exit 1
}
echo "$trace" | grep -F "[step 1]" >/dev/null || {
  echo "FAIL: nydbg step output missing"
  echo "$trace"
  exit 1
}

(
  cd "$tmpd"
  mkdir -p "$tmpd/app"
  "$ROOT_DIR/scripts/nypm.sh" init demo >/dev/null
  "$ROOT_DIR/scripts/nypm.sh" add stdlib "$ROOT_DIR/stdlib" 1.2.0 >/dev/null
  "$ROOT_DIR/scripts/nypm.sh" add app "$tmpd/app" 0.1.0 stdlib@^1.0.0 >/dev/null
  list_out=$("$ROOT_DIR/scripts/nypm.sh" list)
  echo "$list_out" | grep -F "stdlib=$ROOT_DIR/stdlib version=1.2.0" >/dev/null || {
    echo "FAIL: nypm list missing stdlib mapping"
    echo "$list_out"
    exit 1
  }
  echo "$list_out" | grep -F "app=$tmpd/app version=0.1.0 deps=stdlib@^1.0.0" >/dev/null || {
    echo "FAIL: nypm list missing app dependency mapping"
    echo "$list_out"
    exit 1
  }

  resolved=$("$ROOT_DIR/scripts/nypm.sh" resolve app)
  resolved_expected='stdlib
app'
  if [ "$resolved" != "$resolved_expected" ]; then
    echo "FAIL: nypm resolve output incorrect"
    echo "Expected:"
    printf '%s\n' "$resolved_expected"
    echo "Got:"
    printf '%s\n' "$resolved"
    exit 1
  fi

  "$ROOT_DIR/scripts/nypm.sh" dep app stdlib@^2.0.0 >/dev/null
  if "$ROOT_DIR/scripts/nypm.sh" resolve app >/dev/null 2>"$tmpd/resolve_err.log"; then
    echo "FAIL: nypm resolve should fail on semver conflict"
    exit 1
  fi
  grep -q "version conflict" "$tmpd/resolve_err.log" || {
    echo "FAIL: nypm resolve conflict error missing"
    cat "$tmpd/resolve_err.log"
    exit 1
  }

  "$ROOT_DIR/scripts/nypm.sh" dep app stdlib@^1.0.0 >/dev/null
  "$ROOT_DIR/scripts/nypm.sh" lock app >/dev/null
  [ -f "$tmpd/ny.lock" ] || {
    echo "FAIL: nypm lock did not create ny.lock"
    exit 1
  }
  "$ROOT_DIR/scripts/nypm.sh" verify-lock >/dev/null || {
    echo "FAIL: nypm verify-lock failed"
    exit 1
  }
  "$ROOT_DIR/scripts/nypm.sh" install app ./.nydeps >/dev/null || {
    echo "FAIL: nypm install failed"
    exit 1
  }
  [ -d "$tmpd/.nydeps/stdlib" ] || {
    echo "FAIL: nypm install missing stdlib package directory"
    exit 1
  }
  [ -d "$tmpd/.nydeps/app" ] || {
    echo "FAIL: nypm install missing app package directory"
    exit 1
  }
  "$ROOT_DIR/scripts/nypm.sh" doctor >/dev/null || {
    echo "FAIL: nypm doctor failed"
    exit 1
  }
)

cat > "$tmpd/fmt.ny" <<'EOCY'
let x = 1;    
	print(x); 
EOCY

./scripts/nyfmt.sh "$tmpd/fmt.ny" >/dev/null
./scripts/nyfmt.sh --check "$tmpd/fmt.ny" >/dev/null
if grep -n $'\t' "$tmpd/fmt.ny" >/dev/null; then
  echo "FAIL: formatter did not replace tabs"
  exit 1
fi
if grep -nE '[[:space:]]+$' "$tmpd/fmt.ny" >/dev/null; then
  echo "FAIL: formatter left trailing whitespace"
  exit 1
fi

./scripts/nylint.sh "$tmpd/ecosystem.ny" >/dev/null || {
  echo "FAIL: linter failed on ecosystem script"
  exit 1
}

echo "[eco] PASS"
