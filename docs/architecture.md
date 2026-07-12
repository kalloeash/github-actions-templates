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
own folder, `actions/<name>/action.yml`, and can carry its own README.

The rule of thumb: reach for a reusable workflow when the shared unit is whole jobs, and a
composite action when it is steps inside a job.

## Repository layout

| Path | Contents |
|------|----------|
| `.github/workflows/` | Reusable workflow blocks, one file per block. GitHub requires these to be flat, so the file name carries the namespace, for example `dotnet-build-and-test.yml`. |
| `actions/<name>/` | Composite actions, each with an `action.yml` and a README. |
| `fixtures/` | Small sample projects the self-tests run the blocks against. |
| `examples/` | Complete caller files to copy into a consuming repository. |
| `docs/` | This documentation. |

Workflows that are internal to the catalog, such as the self-tests and the release
workflow, use a leading dot in the file name (`.test-<block>.yml`) so the public,
consumable surface is easy to tell apart from the machinery.

## Consuming a block

A consuming repository references a block by path and version:

```yaml
jobs:
  ci:
    uses: kalloeash/github-actions-templates/.github/workflows/<block>.yml@v1
    with:
      # block inputs
```

Pin to a released major tag (`@v1`) or to a full commit SHA. A commit SHA is the only
immutable reference. Do not reference `@main`.

## Versioning and releases

- Releases follow semver (`vX.Y.Z`).
- A moving major tag (`v1`) tracks the latest release in that major line, so consumers on
  `@v1` pick up compatible fixes without editing their caller files.
- Releases are immutable: once published, a release tag stays bound to its commit.
- Third-party actions used inside a block are pinned to a full commit SHA with a version
  comment, and refreshed through Dependabot. This is the mitigation for tag-moving supply
  chain attacks, where an attacker repoints a version tag at a malicious commit.

## Permissions

Every block declares the minimum `permissions:` it needs, starting from `contents: read`
and raising a single scope per job only where required. A called workflow can never hold
more token permission than the caller granted, so the documented minimum is also the
ceiling.

## Testing

- actionlint and zizmor check every workflow file, in pre-commit and in CI.
- gitleaks scans for secrets, on staged changes locally and over the full history in CI.
- Each block has a self-test workflow that calls it against a fixture project, so a change
  that breaks a block cannot merge green.
- Real projects consuming the released tags are the final integration layer.
