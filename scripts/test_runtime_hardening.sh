#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "[hardening] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

cat >"$tmpd/step_limit.nx" <<'CYEOF'
let i = 0;
while (true) {
    i = i + 1;
}
CYEOF

if ./nyx --max-steps 120 "$tmpd/step_limit.nx" >/dev/null 2>"$tmpd/step.err"; then
  echo "FAIL: --max-steps should fail on infinite loop"
  exit 1
fi
grep -q "max step count exceeded" "$tmpd/step.err" || {
  echo "FAIL: missing max step count error"
  cat "$tmpd/step.err"
  exit 1
}

cat >"$tmpd/call_limit.nx" <<'CYEOF'
fn dive(n) {
    return dive(n + 1);
}

dive(0);
CYEOF

if ./nyx --max-call-depth 64 "$tmpd/call_limit.nx" >/dev/null 2>"$tmpd/call.err"; then
  echo "FAIL: --max-call-depth should fail on unbounded recursion"
  exit 1
fi
grep -q "max call depth exceeded" "$tmpd/call.err" || {
  echo "FAIL: missing max call depth error"
  cat "$tmpd/call.err"
  exit 1
}

cat >"$tmpd/ok.nx" <<'CYEOF'
fn add(a, b) {
    return a + b;
}

print(add(40, 2));
CYEOF

out=$(./nyx --max-steps 200 --max-call-depth 64 "$tmpd/ok.nx")
[ "$out" = "42" ] || {
  echo "FAIL: limited runtime produced unexpected output"
  echo "Got: $out"
  exit 1
}

echo "[hardening] PASS"
