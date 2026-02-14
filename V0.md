# v0 Milestone: Native Runtime

Status: `completed`

## Goal

Ship a native `nyx` executable that runs `.ny` files without Python runtime dependency.

## Scope

1. Native build from `native/nyx.c`
2. `./nyx file.ny` launcher path
3. Direct executable script path via shebang (`#!/usr/bin/env nyx`)
4. Stable behavior for v0 language subset

## v0 Language Subset

1. Integer literals
2. Operators: `+ - * /`
3. Parentheses
4. Statement terminator `;`
5. `print(expr);`
6. `#` comments

## Acceptance Criteria

1. `make` builds native runtime to `build/nyx`
2. `./nyx main.ny` executes successfully
3. `PATH="$PWD:$PATH" ./main.ny` executes successfully
4. v0 smoke tests pass (`./scripts/test_v0.sh`)

## Notes

- Python-based implementation is out of v0 runtime path.
- v1 will expand the language for compiler-writing capability.
