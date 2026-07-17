# Architecture

This catalog holds reusable CI building blocks. This document explains how it is
organized, how blocks are versioned and consumed, and how they are tested.

## Two kinds of building block

A reusable workflow is a whole job or set of jobs with its own triggers, permissions, and
secrets. It is used for units like "the pull-request gate for a Node project" or "build and
push a container". GitHub requires reusable workflows to be flat files in
`.github/workflows/`.

A composite action is a bundle of steps that runs inside another job. It is used for shared
mechanics like "set up the runtime and restore the cache". A composite action lives in its
own folder with an `action.yml` and its own README. The catalog holds one:
[install-pinned-tool](../actions/install-pinned-tool/README.md), which downloads a release
archive, verifies its checksum, and installs one binary. It arrived when a fourth workflow
repeated the same install steps, which is the threshold this section always set: a
composite action appears when blocks need the same steps inside their jobs, not before.

A block references the action at the exact commit of its own workflow file, through
`job.workflow_repository` and `job.workflow_sha`, so a block and the action version it
uses can never drift apart: a consumer pinning a release tag gets both from that tag.

The rule of thumb: reach for a reusable workflow when the shared unit is whole jobs, and a
composite action when it is steps inside a job.

## Repository layout

| Path | Contents |
|------|----------|
| `.github/workflows/` | Reusable workflow blocks, one file per block. GitHub requires these to be flat, so the file name carries the namespace, for example `dotnet-build-and-test.yml`. |
| `actions/` | Composite actions, one folder per action with its own README. |
| `docs/blocks/` | One page per block: inputs, secrets, permissions, and copy-paste examples. |
| `docs/` | This documentation. |
| `tests/` | Fixture projects the self-test workflow runs the blocks against, one directory per stack. |

Workflows that are internal to the catalog, such as the release workflow, use a leading
dot in the file name (for example `.release.yml`) so the public, consumable surface is
easy to tell apart from the machinery.

## Consuming a block

A consuming repository references a block by path and version:

```yaml
jobs:
  ci:
    uses: kalloeash/github-actions-templates/.github/workflows/<block>.yml@v0
    with:
      # block inputs
```

Pin to the moving major tag (`@v0` today, `@v1` from 1.0), to an exact release tag, or to
a full commit SHA. A commit SHA is the only immutable reference. Do not reference `@main`.

## Versioning and releases

- Releases follow semver (`vX.Y.Z`).
- A moving major tag (`v0` today, `v1` from 1.0) tracks the latest release in that major
  line, so consumers on the major tag pick up compatible fixes without editing their
  caller files.
- Releases are immutable: once published, a release tag stays bound to its commit.
- Third-party actions used inside a block are pinned to a full commit SHA with a version
  comment, and refreshed through Dependabot. This is the mitigation for tag-moving supply
  chain attacks, where an attacker repoints a version tag at a malicious commit.

## Permissions

Blocks declare the minimum `permissions:` they need, starting from `contents: read` and
raising a single scope per job only where required. A called workflow can never hold more
token permission than the caller granted, so the documented minimum is also the ceiling.

One deliberate exception: `docker-build` declares no permissions block and inherits the
caller's grant. It serves both no-push callers (`contents: read` is enough) and push
callers (which add `packages: write`), and a called workflow that requests more than the
caller granted fails at startup, so a single fixed block cannot serve both. Its
documentation tells callers exactly what to grant per mode.

## Testing

- actionlint and zizmor check every workflow file, in pre-commit and in CI, so interface
  and syntax errors are caught before a block is tagged.
- The self-test workflow (`.test.yml`) runs on pushes to `main` and on every pull
  request. It calls each
  block through its same-repo path against a small fixture project under `tests/`, so a
  change that breaks a block fails in the catalog itself, before it is tagged.
  security-secret-scan is not called from `.test.yml` because the lint workflow consumes
  it directly, which exercises it on the same events. security-dependency-scan is the one
  block not exercised in the catalog: it needs an NVD API key and a long first run, so its
  proof stays with its consumers.
- Release verification runs inside the release workflow (`.release.yml`), on the version
  tag push. On that event, same-repo references resolve to the tagged commit, so every
  block except security-dependency-scan executes at the exact code consumers pin, and the
  GitHub Release and the floating major tag wait for the outcome. It includes
  security-secret-scan, which the pull-request layer leaves to the lint workflow, because
  the lint workflow does not run on tags. A failure opens an issue and nothing is
  published, so a consumer tracking the floating major or the release page can never
  receive an unverified release.
- gitleaks scans for secrets: on staged changes locally, and over the full history in CI,
  where the lint workflow calls the security-secret-scan block. The catalog consumes its
  own block, so the scan and the block's proof are one mechanism.
- A block's integration proof is a real project that consumes it on a pinned tag. Because
  consumers pin tags, a change on `main` never reaches them until they bump, and a broken
  block is caught in that repository's adoption or bump pull request before it merges.
