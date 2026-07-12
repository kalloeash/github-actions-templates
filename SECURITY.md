# Security policy

## Reporting a vulnerability

Report a suspected vulnerability through GitHub private vulnerability reporting on this
repository, under the Security tab, "Report a vulnerability". Do not open a public issue
for security reports.

## Supply-chain posture

- Third-party actions used inside these workflows are pinned to a full commit SHA, with a
  version comment, and refreshed through Dependabot.
- Releases are immutable: a published release tag stays bound to its commit.
- Consumers should pin to a released major tag (`@v1`) or to a full commit SHA, never to
  `@main`.
