# trivy-image-scan

Scan a container image for known vulnerabilities with Trivy and upload the results to GitHub
code scanning, so findings show up as alerts in the Security tab. Standalone because
publishing SARIF needs `security-events: write`, and callers often run it on a schedule to
catch newly disclosed CVEs in an already-published image.

## Usage

Scan a pushed image and fail on CRITICAL or HIGH findings:

```yaml
jobs:
  image-scan:
    permissions:
      contents: read
      security-events: write
    uses: kalloeash/github-actions-templates/.github/workflows/trivy-image-scan.yml@v1
    with:
      image: ghcr.io/${{ github.repository_owner }}/myapp:1.2.3
      registry: ghcr.io
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `image` | (required) | Image reference to scan. |
| `severity` | `CRITICAL,HIGH` | Severities to report and fail on. |
| `scanners` | `vuln` | Trivy scanners to run. |
| `ignore-unfixed` | `false` | Ignore vulnerabilities that have no fix available. |
| `exit-code` | `1` | Exit code when findings exist. `1` fails the build, `0` reports only. |
| `registry` | (none) | Registry to log in to before scanning, to pull a private image. |
| `upload-sarif` | `true` | Upload results to GitHub code scanning. |

## Permissions

`contents: read`, plus `security-events: write` to upload the SARIF report, which the caller
grants on the calling job. The registry login uses the automatic `GITHUB_TOKEN`.

## Notes

- Findings are uploaded as a SARIF report and appear as code scanning alerts in the Security
  tab, under the `trivy-image` category.
- Set `exit-code: 0` to report to the Security tab without failing the build.
- Pass `registry` to pull a private image; the login uses the automatic `GITHUB_TOKEN`.
