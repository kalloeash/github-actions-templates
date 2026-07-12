# security-dependency-scan

Scan project dependencies for known vulnerabilities with OWASP Dependency-Check. Standalone
by design: callers usually run it on a weekly schedule, to catch newly disclosed CVEs, as
well as on pull requests. It needs a free NVD API key.

## Usage

Add this file to the consuming repository at `.github/workflows/dependency-scan.yml`. It is
complete as shown and runs on every pull request and every Monday morning, passing the NVD
API key as a secret:

```yaml
name: dependency-scan
on:
  pull_request:
  schedule:
    - cron: "0 6 * * 1"

jobs:
  dependency-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-dependency-scan.yml@v1
    secrets:
      NVD_API_KEY: ${{ secrets.NVD_API_KEY }}
```

Pass a suppression file to accept reviewed findings:

```yaml
jobs:
  dependency-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-dependency-scan.yml@v1
    with:
      suppression: dependency-check-suppressions.xml
    secrets:
      NVD_API_KEY: ${{ secrets.NVD_API_KEY }}
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `project` | (repository name) | Project name shown in the report. |
| `scan-path` | `.` | Path to scan, relative to the repository root. |
| `fail-on-cvss` | `7` | Fail if a vulnerability at or above this CVSS score is found. |
| `format` | `HTML` | Report format (HTML, JSON, SARIF, ALL). |
| `suppression` | (none) | Path to a suppression file, relative to the repository root. |
| `enable-experimental` | `true` | Enable experimental analyzers. |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `NVD_API_KEY` | yes | NVD API key for the database update. Free at <https://nvd.nist.gov/developers/request-an-api-key>. |

## Permissions

Needs `contents: read` only.

## Notes

- The NVD database is cached with a weekly-rotating key, so most runs skip the full download.
- The scanner image is pinned by digest, not a floating tag.
- The report is uploaded as the `dependency-check-report` artifact.
