# security-iac-scan

Scan infrastructure configuration for misconfigurations with [Trivy](https://trivy.dev).
Trivy detects the configuration types present in the scan path (Terraform, Dockerfiles,
Kubernetes manifests, Helm charts, CloudFormation, Azure ARM, Ansible) and checks them
against its built-in policies. Findings at or above the severity threshold fail the run.

The block is named by purpose, not tool, so the scanner can change without a
consumer-breaking rename. The scan uses the checks embedded in the pinned Trivy binary,
never a runtime download, so a result is reproducible for a given block version and new
checks arrive through a reviewed version bump of the block.

## Usage

Add a job to the pull-request workflow of the consuming repository:

```yaml
name: pr
on:
  pull_request:

jobs:
  iac-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-iac-scan.yml@v0
```

The defaults scan the whole repository and fail on HIGH and CRITICAL findings. New
misconfiguration checks arrive with catalog releases, so a weekly scheduled run catches
findings in configuration that has not changed. Add the schedule in the caller:

```yaml
name: iac-scan
on:
  schedule:
    - cron: "0 6 * * 1"
  pull_request:

jobs:
  iac-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-iac-scan.yml@v0
    with:
      severity: MEDIUM,HIGH,CRITICAL
      trivyignore: .trivyignore
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `scan-path` | `.` | Path to scan, relative to the repository root. |
| `severity` | `HIGH,CRITICAL` | Comma-separated severities that fail the run. |
| `trivyignore` | none | Path to a `.trivyignore` file with suppressed finding IDs. |
| `skip-dirs` | none | Comma-separated directories to exclude from the scan. |
| `sarif-upload` | `false` | Upload results to GitHub code scanning. |

## Permissions

The block inherits the caller's token, like `docker-build`, because its two modes need
different grants and a fixed permissions block cannot serve both:

- Default mode needs `contents: read` only.
- `sarif-upload: true` additionally needs `security-events: write` on the calling job,
  and code scanning enabled on the repository. Code scanning is free on public
  repositories; private repositories need GitHub Code Security.

## Suppressing a finding

Create a `.trivyignore` file in the consuming repository and pass its path through the
`trivyignore` input. One finding ID per line, with a comment explaining why it is
accepted:

```text
# Dev container runs as root on purpose; production image has its own USER.
AVD-DS-0002
```

## Notes

- The scan fails only on findings at or above `severity`; lower findings are printed in
  the log but do not gate.
- Compose files are not a Trivy configuration type. Validating a compose stack is a
  separate concern from misconfiguration scanning and is not covered by this block.
- `--skip-check-update` keeps the run deterministic: the checks are the ones embedded in
  the pinned Trivy binary. This is the same central-bump model the catalog uses for
  gitleaks in security-secret-scan.
