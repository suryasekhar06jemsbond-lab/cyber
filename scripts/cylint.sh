#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Usage: cylint [--strict] [target]
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
if [ "${CYPER_RUNTIME:-}" != "" ] && [ -x "${CYPER_RUNTIME}" ]; then
  runtime="${CYPER_RUNTIME}"
elif [ "${CY_RUNTIME:-}" != "" ] && [ -x "${CY_RUNTIME}" ]; then
  runtime="${CY_RUNTIME}"
elif [ -x "$SCRIPT_DIR/cyper" ]; then
  runtime="$SCRIPT_DIR/cyper"
elif [ -x "$SCRIPT_DIR/cyper.exe" ]; then
  runtime="$SCRIPT_DIR/cyper.exe"
elif [ -x "$SCRIPT_DIR/cy" ]; then
  runtime="$SCRIPT_DIR/cy"
elif [ -x "$SCRIPT_DIR/cy.exe" ]; then
  runtime="$SCRIPT_DIR/cy.exe"
elif command -v cyper >/dev/null 2>&1; then
  runtime="$(command -v cyper)"
elif command -v cyper.exe >/dev/null 2>&1; then
  runtime="$(command -v cyper.exe)"
elif command -v cy >/dev/null 2>&1; then
  runtime="$(command -v cy)"
elif [ -x ./cy ]; then
  runtime=./cy
elif [ -x ./cy.exe ]; then
  runtime=./cy.exe
else
  echo "Error: cyper runtime not found (set CYPER_RUNTIME/CY_RUNTIME or add cyper to PATH)" >&2
  exit 1
fi

lint_file() {
  file="$1"
  "$runtime" --parse-only "$file" >/dev/null
  if [ "$strict" -eq 1 ]; then
    "$SCRIPT_DIR/cyfmt.sh" --check "$file" >/dev/null
  fi
}

if [ -f "$target" ]; then
  lint_file "$target"
else
  find "$target" -type f -name '*.cy' | while IFS= read -r file; do
    lint_file "$file"
  done
fi

echo "Lint complete"
