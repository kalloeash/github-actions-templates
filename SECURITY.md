# Security policy

## Reporting a vulnerability

Report a suspected vulnerability through GitHub private vulnerability reporting on this
repository, under the Security tab, "Report a vulnerability". Do not open a public issue
for security reports.

## Supply-chain posture

- Third-party actions used inside these workflows are pinned to a full commit SHA, with a
  version comment, and refreshed through Dependabot.
- CLI tools installed inside workflow runs (actionlint, gitleaks, git-cliff) are version
  pinned and checksum verified against the values published with their releases. The OWASP
  Dependency-Check container image is pinned by digest. Dependabot does not cover these;
  they are reviewed and bumped by hand.
- Workflow jobs run on numbered runner images (`ubuntu-24.04`), and tool version inputs
  default to pinned versions bumped centrally, so nothing in a run floats to whatever is
  newest.
- Releases are immutable: a published release tag stays bound to its commit.
- Consumers should pin to the moving major tag (`@v0` today), to an exact release tag, or
  to a full commit SHA, never to `@main`. A commit SHA is the only immutable reference.
