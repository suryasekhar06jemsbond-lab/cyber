# Cy Programming Language

Cy runs as a native executable (`cy`) with no Python runtime dependency.

## Build

Requirements:
- C compiler (`cc` / `gcc` / `clang`)
- `make`

```bash
make
```

Runtime binary output:
- `build/cy`

Launcher:
- `./cy`

## Run

```bash
./cy main.cy
./cy examples/fibonacci.cy
```

Executable script style:

```cy
#!/usr/bin/env cy
1 + 2;
```

```bash
chmod +x main.cy
./main.cy
```

## Milestones

- `V0.md`: native runtime baseline
- `V1.md`: compiler-capable runtime features
- `V2.md`: first `.cy` compiler (`compiler/bootstrap.cy`)
- `V3.md`: self-hosting compiler (`compiler/v3_seed.cy`)
- `V4.md`: runtime expansion (loops/comprehensions/class-module-typealias + lint + VM cache)
- `BOOTSTRAP.md`: roadmap to self-hosting (`v2` and `v3`)
- `docs/LANGUAGE_SPEC.md`: language spec draft
- `docs/RELEASE_POLICY.md`: compatibility + release gate contract
- `docs/COMPATIBILITY_LIFECYCLE.md`: deprecation/migration lifecycle
- `SECURITY.md`: vulnerability reporting and response targets
- `CONTRIBUTING.md`: contribution and gate expectations
- `SUPPORT.md`: support workflow

## v3 Compiler (Direct Codegen)

`v3` emits a standalone C compiler source (`compiler/v3_compiler_template.c`) and no longer uses generated runner output for program compilation.
Current direct-codegen source subset:
- literals: int, string, bool, `null`, arrays, object literals
- expressions: arithmetic/comparison/logical/unary (`+ - * / %`, `== != < > <= >=`, `&& ||`, `!`), calls, indexing, member access (`obj.key`), array comprehensions (`for x in y` and `for i, x in y`)
- statements: `let`, assignment (identifier/member/index), expression statements, `if/else if/else`, `while`, `for (x in y)` / `for (k, v in y)`, `break`, `continue`, `try/catch`, `throw`, `fn`, `return`, `import`, `class`, `module`, `typealias`
- compile-time import expansion (module dedup in compiler)
- compiled-in language builtins (numeric helpers `abs/min/max/clamp/sum`, boolean helpers `all/any`, predicates, range/conversion helpers, object/class/version helpers; no stdlib dependency required)
- builtin package imports (`cy:math`, `cy:arrays`, `cy:objects`) resolved without filesystem dependencies

Generate compiler C and build compiler binary:

```bash
./cy compiler/v3_seed.cy compiler/v3_seed.cy compiler_stage1.c
cc -O2 -std=c99 -Wall -Wextra -Werror -o compiler_stage1 compiler_stage1.c
```

Use compiler binary:

```bash
./compiler_stage1 program.cy program.c
cc -O2 -std=c99 -Wall -Wextra -Werror -o program program.c
./program
```

## v2 Compiler

Current scope: compiles a restricted `.cy` input containing a single arithmetic expression statement.
Do not type angle brackets (`< >`); they are placeholders in docs and break in PowerShell.

```bash
./cy compiler/bootstrap.cy input_expr.cy output.c
cc -O2 -std=c99 -Wall -Wextra -Werror -o output_bin output.c
./output_bin
```

```powershell
.\cy compiler\bootstrap.cy input_expr.cy output.c
clang -O2 -std=c99 -Wall -Wextra -Werror -o output_bin.exe output.c
.\output_bin.exe
```

If `clang` is not installed, use one of:

```powershell
gcc -O2 -std=c99 -Wall -Wextra -Werror -o output_bin.exe output.c
```

or (Visual Studio Build Tools `cl`):

```powershell
cl /nologo /W4 /WX output.c /Fe:output_bin.exe
```

## Tooling

Package manager:

```bash
./scripts/cypm.sh init my_project
./scripts/cypm.sh registry set ./cy.registry
./scripts/cypm.sh publish stdlib 1.2.0 ./stdlib
./scripts/cypm.sh search stdlib
./scripts/cypm.sh add-remote stdlib ^1.0.0
./scripts/cypm.sh add stdlib ./stdlib 1.2.0
./scripts/cypm.sh add app ./app 0.1.0 stdlib@^1.0.0
./scripts/cypm.sh dep app "stdlib@^1.0.0,net@>=2.1.0"
./scripts/cypm.sh version app 0.2.0
./scripts/cypm.sh list
./scripts/cypm.sh resolve app
./scripts/cypm.sh lock app
./scripts/cypm.sh verify-lock
./scripts/cypm.sh install app ./.cydeps
./scripts/cypm.sh doctor
```

When constraints include `>` or `<` in shell, quote the argument (for example `"util@>=2.1.0"`).

Formatter:

```bash
./scripts/cyfmt.sh .
./scripts/cyfmt.sh --check .
```

Linter (syntax check):

```bash
./scripts/cylint.sh .
./scripts/cylint.sh --strict .
./cy --parse-only program.cy
```

Debugger (trace + breakpoints + stepper):

```bash
./scripts/cydbg.sh program.cy
./scripts/cydbg.sh --break 12,20 examples/fibonacci.cy
./scripts/cydbg.sh --step-count 5 examples/fibonacci.cy
./scripts/cydbg.sh --step examples/fibonacci.cy
```

Native runtime debug flags (no wrapper):

```bash
./cy --debug --break 12,20 program.cy
./cy --debug --step program.cy
./cy --debug --step-count 10 program.cy
./cy --vm program.cy
./cy --vm-strict program.cy
./cy --max-alloc 1000000 program.cy
./cy --max-steps 100000 program.cy
./cy --max-call-depth 2048 program.cy
./cy --parse-only program.cy
./cy --version
```

PowerShell equivalents:

```powershell
.\scripts\cypm.ps1 init my_project
.\scripts\cypm.ps1 registry set .\cy.registry
.\scripts\cypm.ps1 publish stdlib 1.2.0 .\stdlib
.\scripts\cypm.ps1 search stdlib
.\scripts\cypm.ps1 add-remote stdlib ^1.0.0
.\scripts\cypm.ps1 add stdlib .\stdlib 1.2.0
.\scripts\cypm.ps1 add app .\app 0.1.0 stdlib@^1.0.0
.\scripts\cypm.ps1 version app 0.2.0
.\scripts\cypm.ps1 resolve app
.\scripts\cypm.ps1 lock app
.\scripts\cypm.ps1 verify-lock
.\scripts\cypm.ps1 install app .\.cydeps
.\scripts\cypm.ps1 doctor
.\scripts\cyfmt.ps1 .
.\scripts\cyfmt.ps1 -Check .
.\scripts\cylint.ps1 .
.\scripts\cylint.ps1 -Strict .
.\scripts\cydbg.ps1 --break 12,20 examples\fibonacci.cy
```

## Stdlib

- `stdlib/types.cy`: compatibility helpers (predicates now also available in compiled builtins)
- `stdlib/class.cy`: compatibility helpers (class/object helpers now also available in compiled builtins)

## Test

```bash
./scripts/test_v0.sh
./scripts/test_v1.sh
./scripts/test_v2.sh
./scripts/test_v3_start.sh
./scripts/test_ecosystem.sh
./scripts/test_v4.sh
./scripts/test_compatibility.sh
./scripts/test_registry.sh
./scripts/test_runtime_hardening.sh
./scripts/test_sanitizers.sh
./scripts/test_vm_consistency.sh 1337 300
./scripts/test_vm_program_consistency.sh 5150 120
./scripts/test_fuzz_vm.sh 4242 800
./scripts/test_soak_runtime.sh 60
./scripts/test_production.sh
```

```powershell
.\scripts\test_vm_consistency.ps1 -Seed 1337 -Cases 300
.\scripts\test_vm_program_consistency.ps1 -Seed 5150 -Cases 120
.\scripts\test_fuzz_vm.ps1 -Seed 4242 -Cases 800
.\scripts\test_runtime_hardening.ps1
.\scripts\test_sanitizers.ps1
.\scripts\test_soak_runtime.ps1 -Iterations 60
.\scripts\test_v3.ps1
.\scripts\test_v4.ps1
.\scripts\test_compatibility.ps1
.\scripts\test_registry.ps1
.\scripts\test_production.ps1 -VmCases 300
```

`test_v3.ps1` auto-detects `clang` (including `C:\Program Files\LLVM\bin\clang.exe`), then falls back to `gcc` or `cl`.
`test_production.sh` and `test_production.ps1` are the release gates and include deterministic self-hosting, runtime hardening checks, VM fuzz/soak consistency checks, and tooling smoke tests.
If `pwsh` is installed outside `PATH`, run shell production gate as `PWSH_BIN=/full/path/to/pwsh ./scripts/test_production.sh`.

## v3 Self-Hosting Check

```bash
./cy compiler/v3_seed.cy compiler/v3_seed.cy compiler_stage1.c
cc -O2 -std=c99 -Wall -Wextra -Werror -o compiler_stage1 compiler_stage1.c
./compiler_stage1 compiler/v3_seed.cy compiler_stage2.c --emit-self
cmp compiler_stage1.c compiler_stage2.c
```

```powershell
.\cy.exe compiler\v3_seed.cy compiler\v3_seed.cy compiler_stage1.c
clang -O2 -std=c99 -Wall -Wextra -Werror -o compiler_stage1.exe compiler_stage1.c
.\compiler_stage1.exe compiler\v3_seed.cy compiler_stage2.c --emit-self
cmd /c fc /b compiler_stage1.c compiler_stage2.c
```
