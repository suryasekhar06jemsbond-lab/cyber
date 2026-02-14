#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[v0] building native runtime..."
make >/dev/null

if [ -x ./cyper ]; then
  runtime=./cyper
elif [ -x ./cy ]; then
  runtime=./cy
elif [ -x ./cy.exe ]; then
  runtime=./cy.exe
else
  echo "FAIL: runtime not found (expected ./cyper, ./cy, or ./cy.exe)" >&2
  exit 1
fi

echo "[v0] test: main script via launcher"
out1=$("$runtime" main.cy)
[ "$out1" = "3" ] || {
  echo "FAIL: expected '3', got '$out1'"
  exit 1
}

echo "[v0] test: direct executable .cy"
chmod +x ./main.cy
shim_dir=$(mktemp -d)
trap 'rm -rf "$shim_dir"' EXIT
cat >"$shim_dir/cyper" <<EOF
#!/usr/bin/env sh
exec "$ROOT_DIR/$runtime" "\$@"
EOF
chmod +x "$shim_dir/cyper"
cp "$shim_dir/cyper" "$shim_dir/cy"
chmod +x "$shim_dir/cy"
out2=$(PATH="$shim_dir:$ROOT_DIR:$PATH" ./main.cy)
[ "$out2" = "3" ] || {
  echo "FAIL: expected '3', got '$out2'"
  exit 1
}

echo "[v0] test: arithmetic precedence + print"
tmpf=$(mktemp)
tmpf2=$(mktemp)
trap 'rm -rf "$shim_dir"; rm -f "$tmpf" "$tmpf2"' EXIT
cat >"$tmpf" <<'EOF'
# v0 smoke
print(2 + 3 * 4);
(10 - 4) / 2;
EOF

out3=$("$runtime" "$tmpf")
expected='14
3'
[ "$out3" = "$expected" ] || {
  echo "FAIL: unexpected output"
  echo "Expected:"
  printf '%s\n' "$expected"
  echo "Got:"
  printf '%s\n' "$out3"
  exit 1
}

echo "[v0] test: object literals + methods + try/catch + VM"
cat >"$tmpf2" <<'EOF'
fn inc(self, n) {
    return self.x + n;
}

let obj = {x: 40, inc: inc};
print(obj.inc(2));

try {
    throw "boom";
} catch (err) {
    print(err);
}
EOF

out4=$("$runtime" "$tmpf2")
out5=$("$runtime" --vm "$tmpf2")
expected2='42
boom'
[ "$out4" = "$expected2" ] || {
  echo "FAIL: interpreter output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected2"
  echo "Got:"
  printf '%s\n' "$out4"
  exit 1
}
[ "$out5" = "$expected2" ] || {
  echo "FAIL: VM output mismatch"
  echo "Expected:"
  printf '%s\n' "$expected2"
  echo "Got:"
  printf '%s\n' "$out5"
  exit 1
}

echo "[v0] PASS"
