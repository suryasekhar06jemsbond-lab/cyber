#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]" >&2
  exit 1
fi

if [ -x ./cy ]; then
  runtime=./cy
elif [ -x ./cy.exe ]; then
  runtime=./cy.exe
else
  echo "Error: cy runtime not found (expected ./cy or ./cy.exe)" >&2
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
