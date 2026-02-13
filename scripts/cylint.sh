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

if [ -x ./cy ]; then
  runtime=./cy
elif [ -x ./cy.exe ]; then
  runtime=./cy.exe
else
  echo "Error: cy runtime not found (expected ./cy or ./cy.exe)" >&2
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
