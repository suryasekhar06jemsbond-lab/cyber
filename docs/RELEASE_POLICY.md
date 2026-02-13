# Cy Release Policy

Version: `2026-02-13`

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
2. `cypm lock` writes reproducible resolution to `cy.lock`.
3. `cypm verify-lock` validates that:
- lockfile package paths/versions still match manifest
- locked package paths exist

## Release Gate Minimum

A release is accepted only when all pass:

1. `scripts/test_production.sh`
2. `scripts/test_production.ps1 -VmCases 300`
3. CI workflow `.github/workflows/ci.yml` green on Linux and Windows
