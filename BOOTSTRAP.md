# Cy Bootstrap Plan

Goal: make `cy` independent of Python at runtime, then move toward self-hosting.

## Why Bootstrap Is Required

A new language cannot appear from nothing. You need one initial implementation step:

1. Use an existing toolchain (C/Rust/Python/etc.) to build the first `cy` compiler/runtime.
2. Then rewrite compiler/runtime in `.cy`.
3. Compile that `.cy` compiler using the older compiler.
4. Continue until the newest compiler builds itself.

This is how real languages become self-hosted.

## Stage 0 (Current)

Implementation language: `C`  
Output: native `cy` executable

Current file:
- `native/cy.c`

Build:

```bash
make
./cy main.cy
./scripts/test_v0.sh
```

## Stage 1

Status: `completed`

Objective:
- Expand `native/cy.c` until it supports core language features needed to write a compiler in `.cy`.

Minimum feature checklist:
1. Variables and assignment
2. `if` / `else`
3. Functions and return values
4. Strings and arrays
5. File I/O builtins
6. Module/import support

Deliverable:
- `cy` can run non-trivial `.cy` programs.
- Verification: `./scripts/test_v1.sh`

## Stage 2

Status: `completed`

Objective:
- Write first compiler in `.cy` (for example `compiler/bootstrap.cy`).

Strategy:
1. Keep parser simple.
2. Start by compiling to a small bytecode or C output.
3. Use Stage-1 `cy` to run this compiler.

Deliverable:
- First `.cy` compiler prototype (`compiler/bootstrap.cy`) that compiles a restricted `.cy` subset (single arithmetic expression statement) into C.
- Verification: `./scripts/test_v2.sh`

## Stage 3 (Self-Hosting)

Status: `completed`

Objective:
- Build compiler v2 (written in `.cy`) using compiler v1.
- Rebuild v2 using itself.
- Compare outputs to validate deterministic self-hosting.

Deliverable:
- `cy` compiler can compile its own source.
- Start verification: `./scripts/test_v3_start.sh`
  - Windows: `./scripts/test_v3.ps1`
  - includes rich compile input (`import`, `fn/return`, `if`, arrays/calls)
  - compiles compiler source to chosen output path
  - performs rebuild-and-compare deterministic loop (`--emit-self`)
  - direct code generation path without generated runner indirection
  - class/module/type semantics available directly in compiled output

## Build Discipline

1. Keep language spec versioned (`docs/LANGUAGE_SPEC.md`).
2. Add conformance tests for every syntax feature before implementation.
3. Never remove Stage-0 toolchain until Stage-3 is stable.
4. Tag milestones:
   - `v0`: native runtime
   - `v1`: enough language to write compiler
   - `v2`: first `.cy` compiler
   - `v3`: self-hosting
