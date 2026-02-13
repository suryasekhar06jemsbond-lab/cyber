# Cy Release Policy

Version: `2026-02-13`

Related documents:
1. `docs/COMPATIBILITY_LIFECYCLE.md`
2. `SECURITY.md`

## Stability Targets

1. `cy --version` is the canonical runtime version string.
2. `lang_version()` returns the same version string as `cy --version`.
3. `require_version(v)` must:
- succeed only when `v == lang_version()`
- fail with `language version mismatch` otherwise
4. Runtime behavior validated by release gates:
- `scripts/test_production.sh`
- `scripts/test_production.ps1`

## Compatibility Scope

1. Source compatibility target:
- No silent semantic changes within the same version string.
2. Runtime compatibility target:
- Interpreter path and `--vm-strict` path must agree for supported language forms.
3. Compiler compatibility target:
- `v3` self-hosting determinism must hold (`stage1 == stage2 == stage3` hashes).

## Dependency Resolution Contract (`cypm`)

1. `cypm resolve` enforces dependency graph validity:
- missing package detection
- cycle detection
- semver constraint conflict detection
2. Registry operations:
- `cypm registry set/get` controls package index source (`file` or `http(s)`).
- `cypm search` queries available registry entries.
- `cypm publish` writes versioned entries to file-backed registries.
- `cypm add-remote` selects highest matching semver from registry and adds manifest entry.
3. `cypm lock` writes reproducible resolution to `cy.lock`.
4. `cypm verify-lock` validates that:
- lockfile package paths/versions still match manifest
- locked package paths exist
5. `cypm install` materializes resolved dependency trees into a target directory (default `.cydeps`).
6. `cypm doctor` validates manifest/lock health in one pass.

## Release Gate Minimum

A release is accepted only when all pass:

1. `scripts/test_production.sh`
2. `scripts/test_production.ps1 -VmCases 300`
3. Includes hardening/fuzz/soak gates:
- `scripts/test_registry.sh`
- `scripts/test_runtime_hardening.sh`
- `scripts/test_sanitizers.sh`
- `scripts/test_fuzz_vm.sh`
- `scripts/test_vm_program_consistency.sh`
- `scripts/test_soak_runtime.sh`
4. Sanitizer gate enforces ASan/UBSan/LSan clean runs on supported platforms.
5. CI workflow `.github/workflows/ci.yml` green on Linux and Windows
6. Tag workflow `.github/workflows/release.yml` produces downloadable binary artifacts and checksums
