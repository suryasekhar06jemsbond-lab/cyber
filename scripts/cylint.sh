#!/usr/bin/env sh
set -eu

target=${1:-.}

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
}

if [ -f "$target" ]; then
  lint_file "$target"
else
  find "$target" -type f -name '*.cy' | while IFS= read -r file; do
    lint_file "$file"
  done
fi

echo "Lint complete"
