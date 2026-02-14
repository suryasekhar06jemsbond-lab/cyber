# v2 Milestone: First `.ny` Compiler

Status: `completed`

## Goal

Deliver the first compiler implemented in `.ny`, executed by the native `v1` runtime.

## Compiler Artifact

- Source: `compiler/bootstrap.ny`
- Input: a restricted Nyx source file containing a single arithmetic expression statement
- Output: standalone C program

## CLI

```bash
./nyx compiler/bootstrap.ny input_expr.ny output.c
```

On Windows, compile generated C with any available compiler (`clang`, `gcc`, or `cl`).

## Runtime Additions Required by v2

1. `argc()` builtin
2. `argv(index)` builtin

These are implemented in `native/nyx.c` and allow `.ny` tools to accept terminal arguments.

## Example Flow

```bash
./nyx compiler/bootstrap.ny program.ny program.c
cc -O2 -std=c99 -Wall -Wextra -Werror -o program program.c
./program
```

## Acceptance Checks

1. `make` builds native runtime
2. `./scripts/test_v0.sh` passes
3. `./scripts/test_v1.sh` passes
4. `./scripts/test_v2.sh` passes
