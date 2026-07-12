# github-actions-templates

[![CI](https://github.com/kalloeash/github-actions-templates/actions/workflows/.lint.yml/badge.svg)](https://github.com/kalloeash/github-actions-templates/actions/workflows/.lint.yml)

Reusable GitHub Actions workflows for building, testing, and releasing projects. Define a
CI step once, version it, and consume it from many repositories with a short caller file.

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
    uses: kalloeash/github-actions-templates/.github/workflows/<block>.yml@v0
    with:
      # block inputs, documented per block
```

Pin to the moving major tag (`@v0` today, `@v1` from 1.0), to an exact release tag, or to a
full commit SHA. During `0.x` a minor release may still change an interface, so pin an
exact `@vX.Y.Z` or a SHA if you are not watching the changelog. Do not reference `@main`.

## Catalog

Blocks are added as real projects adopt them. Each block documents its inputs, outputs,
required permissions, and a copy-paste example.

Reusable workflows must be flat files, so each block's category is carried in its file name
prefix rather than a folder.

### Build and test

| Block | Purpose |
|-------|---------|
| [dotnet-build-and-test](docs/blocks/dotnet-build-and-test.md) | Restore, build, and test a .NET solution or project. |
| [node-build-and-test](docs/blocks/node-build-and-test.md) | Format-check, lint, type-check, test, and build a Node project. |

### Container

| Block | Purpose |
|-------|---------|
| [docker-build](docs/blocks/docker-build.md) | Build a container image with Buildx, and optionally push it. |

### Security

| Block | Purpose |
|-------|---------|
| [security-dependency-scan](docs/blocks/security-dependency-scan.md) | Scan dependencies for known vulnerabilities with OWASP Dependency-Check. |
| [security-secret-scan](docs/blocks/security-secret-scan.md) | Scan the full git history for committed secrets with gitleaks. |

### Quality

| Block | Purpose |
|-------|---------|
| [precommit-run](docs/blocks/precommit-run.md) | Run the repository's pre-commit hooks in CI. |

## Versioning and releases

Releases follow semver. A moving major tag (`vN`) tracks the latest release in that major
line, so consumers on `@vN` pick up compatible fixes without editing their caller files.
During `0.x`, pin an exact `@vX.Y.Z` or a commit SHA. Published release tags are immutable.

The changelog is generated from Conventional Commit messages with
[git-cliff](https://git-cliff.org) and published as the notes on each GitHub Release. See
[docs/releasing.md](docs/releasing.md) for how a release is cut.

Third-party actions used inside blocks are pinned to a full commit SHA and refreshed through
Dependabot.

## Contributing

Changes go through a branch and a pull request; nothing is committed straight to `main`.
Branch names use a `type/short-summary` shape, for example `feat/node-build-and-test` or
`chore/foundation`.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org): a
`type(scope): summary` line, for example `feat(docker): add build workflow` or
`docs: expand the versioning notes`.

The same checks run locally through pre-commit and in CI, so what passes on your machine
passes in the pipeline. Install `actionlint`, `zizmor`, and `gitleaks` on your PATH, plus
Python, then enable the hooks:

```sh
pip install pre-commit
pre-commit install
```

CI (`.github/workflows/.lint.yml`, dot-prefixed like all catalog-internal workflows) runs
two jobs:

- format and lint: the pre-commit hooks, including actionlint and zizmor over the workflow files
- secret scan: gitleaks over the git history

## Design

See [docs/architecture.md](docs/architecture.md) for how the catalog is structured: the
two kinds of building block, the repository layout, versioning and pinning, and how blocks
are tested.

## License

MIT. See [LICENSE](LICENSE).
