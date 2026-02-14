#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

seed="${1:-1337}"
cases="${2:-300}"

if ! command -v bash >/dev/null 2>&1; then
  echo "Error: bash is required" >&2
  exit 1
fi

echo "[vm-consistency] building native runtime..."
make >/dev/null

tmpd=$(mktemp -d)
trap 'rm -rf "$tmpd"' EXIT

RANDOM="$seed"
ops=( '+' '-' '*' '==' '!=' '<' '>' '<=' '>=' )

rand_int() {
  echo $((RANDOM % 41 - 20))
}

gen_int_expr() {
  local depth=$1
  local choice op left right

  if [ "$depth" -le 0 ]; then
    rand_int
    return
  fi

  choice=$((RANDOM % 5))
  case "$choice" in
    0)
      rand_int
      ;;
    1)
      echo "(-$(gen_int_expr $((depth - 1))))"
      ;;
    2)
      echo "($(gen_int_expr $((depth - 1))))"
      ;;
    *)
      op="${ops[$((RANDOM % 3))]}" # + - *
      left="$(gen_int_expr $((depth - 1)))"
      right="$(gen_int_expr $((depth - 1)))"
      echo "(($left) $op ($right))"
      ;;
  esac
}

gen_bool_expr() {
  local depth=$1
  local choice op left right

  if [ "$depth" -le 0 ]; then
    op="${ops[$((3 + RANDOM % 6))]}" # == != < > <= >=
    left="$(gen_int_expr 0)"
    right="$(gen_int_expr 0)"
    echo "(($left) $op ($right))"
    return
  fi

  choice=$((RANDOM % 5))
  case "$choice" in
    0)
      op="${ops[$((3 + RANDOM % 6))]}"
      left="$(gen_int_expr $((depth - 1)))"
      right="$(gen_int_expr $((depth - 1)))"
      echo "(($left) $op ($right))"
      ;;
    1)
      echo "(!$(gen_bool_expr $((depth - 1))))"
      ;;
    2)
      echo "($(gen_bool_expr $((depth - 1))))"
      ;;
    *)
      # Equality on bools is valid and VM-supported.
      op="${ops[$((3 + RANDOM % 2))]}" # == !=
      left="$(gen_bool_expr $((depth - 1)))"
      right="$(gen_bool_expr $((depth - 1)))"
      echo "(($left) $op ($right))"
      ;;
  esac
}

gen_expr() {
  local depth=$1
  if [ $((RANDOM % 2)) -eq 0 ]; then
    gen_int_expr "$depth"
  else
    gen_bool_expr "$depth"
  fi
}

echo "[vm-consistency] seed=$seed cases=$cases"
for i in $(seq 1 "$cases"); do
  depth=$((RANDOM % 4 + 1))
  expr="$(gen_expr "$depth")"
  file="$tmpd/case_$i.ny"
  printf '%s;\n' "$expr" > "$file"

  if ! out_ast=$(./nyx "$file" 2>&1); then
    echo "FAIL: AST run failed on case $i"
    echo "expr: $expr"
    printf '%s\n' "$out_ast"
    exit 1
  fi

  if ! out_vm=$(./nyx --vm "$file" 2>&1); then
    echo "FAIL: VM run failed on case $i"
    echo "expr: $expr"
    printf '%s\n' "$out_vm"
    exit 1
  fi

  if [ "$out_ast" != "$out_vm" ]; then
    echo "FAIL: AST/VM mismatch on case $i"
    echo "expr: $expr"
    echo "AST: $out_ast"
    echo "VM:  $out_vm"
    exit 1
  fi
done

echo "[vm-consistency] PASS"
