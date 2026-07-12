# node-build-and-test

Run the standard quality gate for a Node project in one job: a format check, lint, type
check, unit tests, and a production build. The steps run in that order and stop at the first
failure. Every Node project in the fleet calls this one block, so their gates stay identical.

## Usage

Add this file to the consuming repository at `.github/workflows/pr.yml`. It is complete as
shown and runs the gate on every pull request:

```yaml
name: pr
on:
  pull_request:

jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/node-build-and-test.yml@v1
```

The block defaults to Node 24 at the repository root, so `with:` can be omitted. Override
the defaults when needed, for example to pin a version or point at a subdirectory:

```yaml
jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/node-build-and-test.yml@v1
    with:
      node-version: "22"
      working-directory: apps/web
```

## What it runs

The block runs these five npm scripts in order and stops at the first failure. The consuming
`package.json` must define all five; a missing script fails the run, which is deliberate: it
keeps every Node project on the same gate rather than letting one quietly drop a check.

| Order | npm script | Checks that | Conventional command |
|-------|------------|-------------|----------------------|
| 1 | `format:check` | formatting is consistent | `prettier --check .` |
| 2 | `lint` | static analysis passes | `eslint .` |
| 3 | `typecheck` | there are no type errors | `tsc --noEmit` |
| 4 | `test` | unit tests pass | `vitest run` |
| 5 | `build` | the app builds | `next build` |

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `node-version` | `24` | Node.js version passed to actions/setup-node. |
| `working-directory` | `.` | Directory the npm commands run in. The lockfile is read from here. |

## Permissions

Needs `contents: read` only, which is the default a called workflow receives, so the caller
grants nothing extra.

## Notes

- npm dependencies are cached by actions/setup-node, keyed on the lockfile, so repeat runs
  skip the download.
- The checks run cheapest first, so a formatting or lint error fails the run before the
  slower test and build steps.
- There are no toggles on purpose: the gate is identical for every Node project. If a
  project genuinely cannot run one of the checks, add a toggle input to the block then,
  rather than skipping the check in the caller.
- During `0.x`, pin an exact version such as `@v0.2.0`. `@v1` tracks the latest v1 release
  once the catalog reaches 1.0.
