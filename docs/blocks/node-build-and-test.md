# node-build-and-test

Run the standard quality gate for a Node project: format check, lint, type check, unit
test, and a production build. The steps run as one job, like the dotnet block, so the run
stops at the first failing check. Every Node project in the fleet runs the same five
checks, so their gates cannot drift apart.

## Usage

```yaml
jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/node-build-and-test.yml@v1
    with:
      node-version: "24"
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `node-version` | `24` | Node.js version passed to actions/setup-node. |
| `working-directory` | `.` | Directory the npm commands run in. |

## Script contract

The calling project must define these npm scripts. They run in this order, and a missing
script fails the run:

| Step | npm script | Conventional command |
|------|------------|----------------------|
| Format check | `format:check` | `prettier --check .` |
| Lint | `lint` | `eslint .` |
| Type check | `typecheck` | `tsc --noEmit` |
| Test | `test` | `vitest run` |
| Build | `build` | `next build` |

## Permissions

Needs `contents: read` only, which is the default. The block reads the source and writes
nothing back.

## Notes

- npm dependencies are cached by actions/setup-node, keyed on the lockfile.
- The checks run cheapest first, so a formatting or lint error fails the run before the
  slower test and build steps.
- There are no toggles on purpose: the gate is identical for every Node project. If a
  project genuinely cannot run one of the checks, add a toggle input to the block then,
  rather than skipping the check in the caller.
