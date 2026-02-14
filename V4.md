# v4 Milestone: Runtime Expansion

Status: `completed` (runtime layer)

## Goal

Expand Nyx runtime expressiveness and tooling beyond the v3 bootstrap baseline.

## Implemented

1. Control-flow expansion
- `while (...) { ... }`
- `for (item in iterable) { ... }` for arrays and objects (object iteration yields keys)
- `for (k, v in iterable) { ... }` dual-variable iteration:
  - arrays: `k=index`, `v=value`
  - objects: `k=key`, `v=value`
- `break;` and `continue;`

2. Syntax expansion
- Array comprehensions: `[expr for x in iterable if cond]`
- Dual-variable comprehensions: `[expr for k, v in iterable if cond]`
- `else if (...) { ... }` conditional chaining
- Added operators: `%`, `&&`, `||`, `??`
- `switch/case/default` branching syntax
- Assignment targets beyond identifiers:
  - member assignment: `obj.key = value;`
  - index assignment: `arr[i] = value;`, `obj["k"] = value;`
- `class Name { ... }` declaration syntax
- `module Name { ... }` declaration syntax
- `typealias Name = expr;` declaration syntax

3. Object/class runtime model
- Object kinds: plain/module/class/instance
- Module-safe member access (no implicit receiver binding on module calls)
- Instance method dispatch through `__class__` fallback
- `new(class_obj, ...)` builtin with `init(self, ...)` constructor convention
- Expanded builtins:
  - conversions/utilities: `range`, `str`, `int`
  - numeric helpers: `abs`, `min`, `max`, `clamp`, `sum`
  - boolean helpers: `all`, `any`
  - object utilities: `values`, `items`, `has`
  - class helpers: `class_new`, `class_with_ctor`, `class_set_method`, `class_name`, `class_instantiate0/1/2`, `class_call0/1/2`
  - builtin packages: `nymath`, `nyarrays`, `nyobjects`, `nyjson`, `nyhttp` (importable without files)

4. VM/performance hardening
- `--vm` executes parsed programs through statement-block bytecode dispatch and expression bytecode
- Added bytecode caches for hot expressions and parsed blocks
- `--vm-strict` enforces no VM fallback for supported syntax

5. Tooling depth
- Added linter wrappers:
  - `scripts/nylint.sh`
  - `scripts/nylint.ps1`
- Added formatter check mode:
  - `scripts/nyfmt.sh --check`
  - `scripts/nyfmt.ps1 -Check`
- Added package doctor command:
  - `scripts/nypm.sh doctor`
  - `scripts/nypm.ps1 doctor`
- Runtime parser/lint mode:
  - `nyx --parse-only file.ny`
  - `nyx --lint file.ny`
- Added acceptance test:
  - `scripts/test_v4.sh`

6. Compatibility hooks
- `lang_version()` builtin
- `require_version("...")` builtin for explicit runtime compatibility checks
- `--max-alloc N` allocation guard for runaway-script protection
- `--max-steps N` statement-step guard
- `--max-call-depth N` recursion depth guard

## Validation

All existing and new scripts pass:

```bash
./scripts/test_v0.sh
./scripts/test_v1.sh
./scripts/test_v2.sh
./scripts/test_v3_start.sh
./scripts/test_ecosystem.sh
./scripts/test_v4.sh
./scripts/test_runtime_hardening.sh
./scripts/test_sanitizers.sh
./scripts/test_vm_program_consistency.sh
./scripts/test_fuzz_vm.sh
./scripts/test_soak_runtime.sh
```

## Note

Direct C codegen (`compiler/v3_compiler_template.c`) now covers most v4 statement-level syntax:
- `while` / `for` / `break` / `continue`
- dual-variable `for` and comprehensions
- `else if` chains
- `%` operator and logical/null-coalescing operators (`&&`, `||`, `??`)
- `switch/case/default`
- `class` / `module` / `typealias`
- member/index assignment
- expanded builtins (`abs/min/max/clamp/sum/all/any`, `range`, `str`, `int`, `keys/values/items/has`, `new`, class helpers, `lang_version`, `require_version`)
- builtin package import expansion (`nymath`, `nyarrays`, `nyobjects`, `nyjson`, `nyhttp`)
