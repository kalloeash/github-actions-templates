# install-pinned-tool

Download a release asset, verify its checksum against the value published with the
release, and install a single binary from it. The asset is either a `.tar.gz` archive
holding the binary or the binary itself. Every CLI tool the catalog's workflows use
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

For anything not in the table, pass the asset URL and its published checksum. Use
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

A URL that does not end in `.tar.gz` or `.tgz` is installed as the binary itself, for
projects that publish bare binaries. `archive-member` does not apply and is rejected:

```yaml
- uses: ./actions/install-pinned-tool
  with:
    tool: jq
    url: https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-linux-amd64
    sha256: b1c22172dd303f3be49e935aa56aa48a8b7a46e0bc838b4997d3bb451495870f
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `tool` | required | Binary to install. Table tools: `actionlint`, `gitleaks`, `osv-scanner`, `trivy`. Any other name requires `url` and a checksum. |
| `url` | none | Release asset URL. Overrides the pin table. `.tar.gz` and `.tgz` URLs are archives; any other URL is the binary itself. |
| `sha256` | none | SHA-256 checksum of the asset. Required with `url` unless `sha512` is given. |
| `sha512` | none | SHA-512 checksum, for releases that publish SHA-512 values. |
| `archive-member` | tool name | Path of the binary inside a `.tar.gz` archive. Rejected for a single-binary asset. |

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
- Give `url` exactly one checksum. `sha256` and `sha512` together are rejected, and so is
  a checksum without `url`, because the pin table owns the checksums of its own tools.
- Only the named archive member is extracted; the archive is never unpacked wholesale
  into the working tree. `archive-member` must be a relative path inside the archive;
  absolute paths and `..` segments are rejected.
- A single-binary asset is verified and installed as it is. Giving `archive-member` with
  such a URL is rejected, so a mistyped archive URL fails instead of installing the
  archive as a binary.
- The download retries transient failures three times; a changed or missing asset still
  fails.
- Linux amd64 runners only, matching the catalog's blocks.
