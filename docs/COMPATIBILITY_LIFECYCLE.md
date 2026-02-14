# Compatibility Lifecycle

Version: `2026-02-13`

## Goals

1. Keep stable behavior for published language/runtime versions.
2. Avoid silent breaking changes.
3. Provide explicit migration paths when behavior changes are required.

## Versioning Rules

1. `nyx --version` and `lang_version()` must match.
2. Breaking language/runtime changes require a new version string.
3. Non-breaking additions may be released under the same major line.

## Deprecation Process

1. Announce deprecation in docs and release notes.
2. Keep deprecated behavior available for at least one full release cycle.
3. Emit clear runtime error/warning guidance for removed behavior.
4. Provide migration examples before removal.

## Removal Process

1. Update `docs/LANGUAGE_SPEC.md` and `README.md`.
2. Add migration examples.
3. Keep compatibility tests for old behavior until removal release is cut.
4. Enforce new behavior with production gates.

## Gate Requirements

Any compatibility-affecting release must pass:
1. `scripts/test_compatibility.sh`
2. `scripts/test_compatibility.ps1`
3. `scripts/test_production.sh`
4. `scripts/test_production.ps1 -VmCases 300`
