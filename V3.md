# v3 Milestone: Self-Hosting Compiler

Status: `completed`

## Goal

Produce a self-hosting compiler flow for the current Nyx bootstrap architecture.

## What Is Implemented

1. Self-hosting compiler source in `.ny`
- File: `compiler/v3_seed.ny`
- Emits standalone C compiler source from `compiler/v3_compiler_template.c`

2. Compiler binary modes
- Normal mode: compile `.ny` source into direct C output
- Self mode: `--emit-self` emits the compiler's own C source (`__FILE__` copy)

3. Deterministic rebuild loop
- Stage1: runtime (`./nyx`) -> `compiler_stage1.c`
- Stage2: `compiler_stage1` -> `compiler_stage2.c` (`--emit-self`)
- Stage3: `compiler_stage2` -> `compiler_stage3.c` (`--emit-self`)
- Determinism checks: `stage1.c == stage2.c == stage3.c`

4. Non-trivial source validation
- Rebuilt compiler compiles a richer source set:
  - `import`
  - `fn` / `return`
  - arrays + indexing
  - object literals + member access (`obj.key`)
  - member/index assignment (`obj.k = v`, `obj["k"] = v`, `arr[i] = v`)
  - method-style calls with bound receiver (`obj.method(...)`)
  - `if / else`, `while`, `for (x in y)`, `break`, `continue`
  - `class`, `module`, `typealias`
  - `try / catch / throw`
  - function calls
  - class/object/type/version builtins emitted into generated C runtime (`new`, `keys`, `lang_version`, `require_version`)

## Acceptance Check

```bash
./scripts/test_v3_start.sh
```

```powershell
.\scripts\test_v3.ps1
```

## Notes

This achieves self-hosting for the current compiler model.
Current direct-codegen path includes loops, class/module/type syntax, exceptions, functions, imports, object/array syntax, and compiled-in class/type/version semantics.
Remaining gap: array comprehensions are runtime-only today (not direct-codegen).
