#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]" >&2
  exit 1
fi

case "${1:-}" in
  --help|-h)
    echo "Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]"
    exit 0
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runtime=""

if [ "${CY_RUNTIME:-}" != "" ] && [ -x "${CY_RUNTIME}" ]; then
  runtime="${CY_RUNTIME}"
elif [ -x "$SCRIPT_DIR/cy" ]; then
  runtime="$SCRIPT_DIR/cy"
elif [ -x "$SCRIPT_DIR/cy.exe" ]; then
  runtime="$SCRIPT_DIR/cy.exe"
elif command -v cy >/dev/null 2>&1; then
  runtime="$(command -v cy)"
elif [ -x ./cy ]; then
  runtime=./cy
elif [ -x ./cy.exe ]; then
  runtime=./cy.exe
else
  echo "Error: cy runtime not found (set CY_RUNTIME or add cy to PATH)" >&2
  exit 1
fi

has_mode=0
for arg in "$@"; do
  case "$arg" in
    --break|--step|--step-count)
      has_mode=1
      break
      ;;
  esac
done

if [ "$has_mode" -eq 1 ]; then
  exec "$runtime" "$@"
fi

exec "$runtime" --debug "$@"
