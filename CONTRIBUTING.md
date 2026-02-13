# Contributing

## Development Setup

1. Install a C compiler (`clang`, `gcc`, or `cl`).
2. Build runtime:

```bash
make
```

3. Run full gate before opening a PR:

```bash
./scripts/test_production.sh
```

On PowerShell:

```powershell
.\scripts\test_production.ps1 -VmCases 300
```

## Change Requirements

1. Add or update tests for behavior changes.
2. Keep docs in sync (`README.md`, `docs/LANGUAGE_SPEC.md`, release policy docs).
3. Preserve compatibility rules in `docs/RELEASE_POLICY.md`.
4. For breaking changes, add migration notes and deprecation timeline.

## Commit and PR Expectations

1. Keep commits scoped and reviewable.
2. Include motivation, design, and risk notes in PR description.
3. Include test evidence (commands + pass/fail output summary).
