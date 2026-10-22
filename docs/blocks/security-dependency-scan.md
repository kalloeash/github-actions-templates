# security-dependency-scan

Scan dependency lockfiles and manifests for known vulnerabilities with
[OSV-Scanner](https://google.github.io/osv-scanner/). It reads the files in the scan path
(for example `package-lock.json`, `packages.lock.json`, `.csproj`, `go.mod`,
`requirements.txt`) and asks the [OSV.dev](https://osv.dev) database about the exact
package versions. OSV.dev includes the GitHub Advisory Database, the same source as
`npm audit` and NuGet's audit.

There is no vulnerability database to download and no API key, so a scan takes seconds.
A finding that the config does not ignore fails the run, whatever its severity.

The block is named by purpose, not tool, so the scanner can change without a
consumer-breaking rename.

## Usage

Add a job to the pull-request workflow of the consuming repository:

```yaml
name: pr
on:
  pull_request:

jobs:
  dependency-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-dependency-scan.yml@v0
```

Advisories are published every day against versions that have not changed, so a weekly
scheduled run catches them between pull requests:

```yaml
name: dependency-scan
on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

jobs:
  dependency-scan:
    uses: kalloeash/github-actions-templates/.github/workflows/security-dependency-scan.yml@v0
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `scan-path` | `.` | Directory scanned recursively for lockfiles and manifests. |
| `lockfiles` | none | Lockfiles to scan instead of `scan-path`, one per line. Prefix a path with its format and a colon (`package-lock.json:path/to/file`) when the file name does not show it. |
| `config` | none | Path to an `osv-scanner.toml` applied to every scanned file. Empty uses the `osv-scanner.toml` next to each scanned file, if any. |
| `fail-on-vuln` | `true` | Fail the run when a vulnerability is found that the config does not ignore. |
| `artifact-name` | `dependency-scan-report` | Name of the uploaded JSON report. Must be unique per workflow run when the block is called more than once. |

## Outputs

| Name | Description |
|------|-------------|
| `vulnerability-count` | Number of distinct advisories found, after the config's ignores. An advisory and its aliases (a GHSA and its CVE) count once. |

## Permissions

Needs `contents: read` only.

## Ignoring a finding

Put an `osv-scanner.toml` next to the lockfile, or pass one through `config`. Ignore one
advisory until a date, with the reason:

```toml
[[IgnoredVulns]]
id = "GHSA-vfj7-8cjw-p6xm"
ignoreUntil = 2027-01-31
reason = "Linter dependency only, no fixed release yet."
```

Or ignore whole groups of packages. Development dependencies do not ship with the
application, so a repository can choose to gate on production dependencies only:

```toml
[[PackageOverrides]]
group = "dev"
ignore = true
reason = "Development tooling is not part of the shipped application."
```

Every key is described in the
[OSV-Scanner configuration docs](https://google.github.io/osv-scanner/configuration/).

## Notes

- Each finding is listed in the job summary with its advisory, severity, package,
  version, and file. The full JSON report is uploaded as an artifact.
- A scan path without any lockfile or manifest fails the run, so a misconfigured path
  does not pass silently.
- OSV-Scanner reads lockfiles and manifests, not built artifacts. Vulnerabilities in a
  container base image are outside this block.
- The scan queries the OSV.dev API at run time, so results follow the live advisory data
  rather than the block version. osv-scanner itself is pinned and checksum verified in
  the catalog's install-pinned-tool action.
