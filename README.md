# github-actions-templates

Reusable GitHub Actions workflows and composite actions for building, testing, and
releasing projects. Define a CI step once, version it, and consume it from many
repositories with a short caller file.

## Why

Repositories tend to copy the same CI jobs: set up a runtime, lint, test, build a
container, scan for secrets and dependencies. Copied YAML drifts, and every fix has to be
repeated in every repository. This catalog holds each step once. A repository references a
block by version and picks up fixes on the next version bump.

## Using a block

Reference a workflow from your own workflow file:

```yaml
jobs:
  ci:
    uses: kalloeash/github-actions-templates/.github/workflows/<block>.yml@v1
    with:
      # block inputs, documented per block
```

Pin to a released major tag (`@v1`) or to a full commit SHA. Do not reference `@main`.

## Catalog

Blocks are added as real projects adopt them. Each block documents its inputs, outputs,
required permissions, and a copy-paste example.

| Block | Purpose |
|-------|---------|
| _none yet_ | Blocks land here as they are built. |

## Versioning

Releases follow semver. A moving major tag (`v1`) tracks the latest release in that major
line. Third-party actions used inside blocks are pinned to a full commit SHA and refreshed
through Dependabot.

## Contributing

Workflow and action files are checked with actionlint and zizmor, and the repository runs
pre-commit and gitleaks over each change. Install `actionlint`, `zizmor`, and `gitleaks`
on your PATH, then enable the hooks:

```sh
pip install pre-commit
pre-commit install
```

## License

MIT. See [LICENSE](LICENSE).
