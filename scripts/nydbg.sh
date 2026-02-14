#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: nydbg [--break line1,line2] [--step] [--step-count N] <file.ny> [args...]" >&2
  exit 1
fi

case "${1:-}" in
  --help|-h)
    echo "Usage: nydbg [--break line1,line2] [--step] [--step-count N] <file.ny> [args...]"
    exit 0
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runtime=""

if [ "${NYX_RUNTIME:-}" != "" ] && [ -x "${NYX_RUNTIME}" ]; then
  runtime="${NYX_RUNTIME}"
elif [ -x "$SCRIPT_DIR/nyx" ]; then
  runtime="$SCRIPT_DIR/nyx"
elif [ -x "$SCRIPT_DIR/nyx.exe" ]; then
  runtime="$SCRIPT_DIR/nyx.exe"
elif command -v nyx >/dev/null 2>&1; then
  runtime="$(command -v nyx)"
elif command -v nyx.exe >/dev/null 2>&1; then
  runtime="$(command -v nyx.exe)"
elif [ -x ./nyx ]; then
  runtime=./nyx
elif [ -x ./nyx.exe ]; then
  runtime=./nyx.exe
else
  echo "Error: nyx runtime not found (set NYX_RUNTIME or add nyx to PATH)" >&2
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
