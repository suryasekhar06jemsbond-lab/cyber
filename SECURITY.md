# Security Policy

## Supported Version

Security fixes are applied to the `main` branch and included in the next release cut.

## Reporting a Vulnerability

1. Do not open a public issue for exploitable bugs.
2. Send a private report to the project maintainers with:
- affected version/commit
- reproduction steps
- impact assessment
- any proposed patch
3. Maintainers will acknowledge within 72 hours and provide a triage status.

## Response Targets

1. Initial triage: within 72 hours
2. Confirmed critical/high issue patch target: within 7 days
3. Medium/low issue patch target: next scheduled release

## Security Release Process

1. Reproduce and scope impact.
2. Patch on protected branch.
3. Run release gates:
- `scripts/test_production.sh`
- `scripts/test_production.ps1 -VmCases 300`
4. Publish advisory with mitigation and upgrade instructions.

## Proprietary Notice

**This software is PROPRIETARY and CONFIDENTIAL.**

Unauthorized access, use, reproduction, or distribution of this software is strictly prohibited and may result in civil and criminal penalties.

See the [LICENSE](LICENSE) file for full terms and conditions regarding:
- Usage rights and restrictions
- Confidentiality obligations
- Intellectual property protections
- Prohibited activities
- Enforcement and liability

Copyright (c) 2026 Surya Sekhar Roy. All Rights Reserved.
