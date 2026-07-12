# security-secret-scan

Scan the full git history for committed secrets with gitleaks. This is the unbypassable CI
backstop to the gitleaks pre-commit hook: the hook catches a secret on a developer's machine
before it is committed, and this block catches anything that reaches the repository, across
the whole history and for every contributor.

## Usage

Add this file to the consuming repository at `.github/workflows/secret-scan.yml`, or add the
job to an existing pull-request workflow. It is complete as shown and runs on every pull
request:

```yaml
name: secret-scan
on:
  pull_request:

jobs:
  secret-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-secret-scan.yml@v0
```

## Inputs

None. The block is deliberately opinionated: it scans the whole history with the pinned
gitleaks version, which keeps every consumer on the same scanner.

## Permissions

Needs `contents: read` only.

## Notes

- The scan reads the entire history, so the block checks out with `fetch-depth: 0`.
- gitleaks is pinned to a fixed version and checksum-verified on download. The version is
  bumped centrally, so a consumer picks up a new gitleaks with one tag bump, the same way the
  dependency scanner owns its image version.
- Findings are redacted in the log, so a matched secret value is never printed.
- gitleaks reads a `.gitleaks.toml` from the repository root if present, for allowlisting
  reviewed findings.
- Pair it with the official gitleaks pre-commit hook for local feedback; this block is the
  history-wide gate that a skipped or uninstalled hook cannot bypass.
