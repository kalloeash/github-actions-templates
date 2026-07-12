# github-actions-templates

[![CI](https://github.com/kalloeash/github-actions-templates/actions/workflows/lint.yml/badge.svg)](https://github.com/kalloeash/github-actions-templates/actions/workflows/lint.yml)

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
| [dotnet-build-and-test](docs/blocks/dotnet-build-and-test.md) | Restore, build, and test a .NET solution or project. |
| [precommit-run](docs/blocks/precommit-run.md) | Run the repository's pre-commit hooks in CI. |
| [docker-build](docs/blocks/docker-build.md) | Build a container image with Buildx, and optionally push it. |

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
Branch names use a `type/short-summary` shape, for example `feat/node-checks` or
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

CI (`.github/workflows/lint.yml`) runs two jobs:

- format and lint: the pre-commit hooks, including actionlint and zizmor over the workflow files
- secret scan: gitleaks over the git history

## Design

See [docs/architecture.md](docs/architecture.md) for how the catalog is structured: the
two kinds of building block, the repository layout, versioning and pinning, and how blocks
are tested.

## License

MIT. See [LICENSE](LICENSE).
