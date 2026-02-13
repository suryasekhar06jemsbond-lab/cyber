#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

seed="${1:-4242}"
cases="${2:-800}"
prog_cases=$((cases / 4))
if [ "$prog_cases" -lt 30 ]; then
  prog_cases=30
fi

echo "[fuzz-vm] seed=$seed cases=$cases"
./scripts/test_vm_consistency.sh "$seed" "$cases"
./scripts/test_vm_program_consistency.sh "$seed" "$prog_cases"
echo "[fuzz-vm] PASS"
