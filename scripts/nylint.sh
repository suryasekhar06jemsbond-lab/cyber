#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Usage: nylint [--strict] [target(.ny)]
USAGE
}

strict=0
target="."
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      strict=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ "$target" != "." ]; then
        echo "Error: multiple targets are not supported" >&2
        usage >&2
        exit 1
      fi
      target="$1"
      ;;
  esac
  shift
done

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

lint_file() {
  file="$1"
  "$runtime" --parse-only "$file" >/dev/null
  if [ "$strict" -eq 1 ]; then
    "$SCRIPT_DIR/nyfmt.sh" --check "$file" >/dev/null
  fi
}

if [ -f "$target" ]; then
  lint_file "$target"
else
  find "$target" -type f -name '*.ny' | while IFS= read -r file; do
    lint_file "$file"
  done
fi

echo "Lint complete"