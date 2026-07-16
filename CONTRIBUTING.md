# Contributing

Contributions are welcome: fixes, hardening, documentation, and new blocks that come with
a real consumer. This page covers the local setup, the workflow, and what a complete
change looks like.

## Local setup

The pre-commit hooks run the same checks locally that the lint workflow runs in CI. CI
also runs the self-tests, which call each block against a fixture project under `tests/`.

1. Install the three CLI tools on your PATH: [actionlint](https://github.com/rhysd/actionlint),
   [zizmor](https://github.com/zizmorcore/zizmor), and
   [gitleaks](https://github.com/gitleaks/gitleaks). Python is also required.
2. Enable the hooks:

   ```sh
   pip install pre-commit
   pre-commit install
   ```

3. Before pushing, run everything once: `pre-commit run --all-files`.

## Workflow

- Branch from `main` using a `type/short-summary` name, for example `feat/go-build-and-test`
  or `fix/docker-build-cache-scope`.
- Nothing is committed straight to `main`; every change goes through a pull request and is
  squash-merged. The pull request title becomes the commit message, so give it the same
  care.
- Commit messages and PR titles follow
  [Conventional Commits](https://www.conventionalcommits.org): a `type(scope): summary`
  line, for example `feat(docker): add build workflow` or `docs: expand the versioning
  notes`. The changelog and release notes are generated from these.

## What a complete block change contains

A new block, or a change to a block's interface, is complete when it has all of:

1. **The workflow file**, following the house rules below.
2. **A self-test.** A job in `.github/workflows/.test.yml` that calls the block against a
   fixture project under `tests/`, so the catalog proves the block runs on every pull
   request. A block that cannot run against a fixture, such as one needing a paid or
   rate-limited service, documents why in the testing section of
   [docs/architecture.md](docs/architecture.md) instead.
3. **A documentation page** at `docs/blocks/<block>.md` with the same structure as the
   existing pages: a one-paragraph summary, a complete copy-paste caller example, the
   inputs table, secrets if any, the required permissions, and notes for the sharp edges.
   The README catalog table gets a row.
4. **A consumer.** Blocks exist for real projects, not for completeness. Name the
   repository that will call the block, or the concrete project it is being built for. A
   block nobody calls gets removed.

Fixes and documentation changes need only themselves plus green checks.

## House rules for workflow files

These are the rules the existing blocks follow; a review will hold new code to them.

- Names are lowercase kebab-case: `<stack-or-tool>-<verb-phrase>.yml`. Workflows internal
  to the catalog carry a leading dot (`.lint.yml`, `.test.yml`, `.release.yml`).
- Third-party actions are pinned to a full commit SHA with a `# vX.Y.Z` comment.
  Dependabot refreshes the pins.
- Binaries installed inside a run are version pinned and checksum verified against the
  values published with their release.
- `permissions:` declares the minimum, starting from `contents: read`. If a block must
  inherit the caller's token (see `docker-build`), the reason is documented in the file
  and in the block's page.
- Inputs reach shell steps through `env:`, never interpolated into `run:` scripts.
- Every job has `timeout-minutes`.
- Consumer-specific values are inputs with sensible defaults; nothing project-specific is
  hardcoded.
- Write plainly: short, factual sentences in docs, comments, and commit messages.

## Reporting problems

Open an issue for bugs and proposals. For anything security-sensitive, use private
vulnerability reporting instead; see [SECURITY.md](SECURITY.md).
