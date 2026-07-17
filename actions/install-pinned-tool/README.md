# install-pinned-tool

Download a release archive, verify its checksum against the value published with the
release, and install a single binary from it. Every CLI tool the catalog's workflows use
is installed through this action, so the version and checksum for each tool live in one
pin table instead of being repeated per workflow.

## Usage

### Pin-table mode

For tools the catalog owns, name the tool and nothing else. Version, URL, and checksum
come from the pin table in [`action.yml`](action.yml); bumping a tool is a one-line
reviewed change that reaches every workflow at once:

```yaml
- uses: ./actions/install-pinned-tool
  with:
    tool: gitleaks
```

### Explicit mode

For anything not in the table, pass the archive URL and its published checksum. Use
`sha512` when a project publishes SHA-512 values, and `archive-member` when the binary is
nested inside the archive:

```yaml
- uses: ./actions/install-pinned-tool
  with:
    tool: git-cliff
    url: https://github.com/orhun/git-cliff/releases/download/v2.13.1/git-cliff-2.13.1-x86_64-unknown-linux-gnu.tar.gz
    sha512: e716cce3a07dda41b1e370d6afbd7a59eb3d4739509fb7856aeec8da2be28c0396584e29e106141c1a1c535c1827dbc1f60417524f5cfb1da9e11f700bd00f30
    archive-member: git-cliff-2.13.1/git-cliff
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `tool` | required | Binary to install. Table tools: `actionlint`, `gitleaks`, `trivy`. Any other name requires `url` and a checksum. |
| `url` | none | Release archive URL. Overrides the pin table. |
| `sha256` | none | SHA-256 checksum of the archive. Required with `url` unless `sha512` is given. |
| `sha512` | none | SHA-512 checksum, for releases that publish SHA-512 values. |
| `archive-member` | tool name | Path of the binary inside the archive. |

## How a reusable workflow references this action

A reusable workflow runs against the calling repository's checkout, so `./actions/...`
would resolve into the caller's tree. Blocks therefore check out the catalog's own source
first, at the exact commit of the workflow file that is running, and reference the action
from that checkout:

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    repository: ${{ job.workflow_repository }}
    ref: ${{ job.workflow_sha }}
    path: .catalog
    sparse-checkout: actions
    persist-credentials: false
- uses: ./.catalog/actions/install-pinned-tool
  with:
    tool: gitleaks
- name: Remove the catalog checkout
  run: rm -rf .catalog
```

`job.workflow_repository` and `job.workflow_sha` identify the repository and commit the
running workflow file came from, so a block and the action version it uses can never
drift apart: a consumer pinning `@v0.6.0` gets both from that tag. The sparse checkout
keeps the extra clone to the `actions/` folder, and removing it afterwards keeps the
job's working tree equal to the caller's repository. Workflows internal to this catalog
skip all of that and use the local `./actions/...` path directly.

## Notes

- The checksum is compared by value, not filename, so a renamed or replaced release
  asset fails the job.
- Only the named archive member is extracted; the archive is never unpacked wholesale
  into the working tree.
- Linux runners only, matching the catalog's blocks.
