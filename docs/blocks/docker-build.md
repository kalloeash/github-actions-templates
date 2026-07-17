# docker-build

Build a container image with Buildx, and optionally push it. Pull-request verification and
release push are the same workflow: leave `push` false to verify the build on a PR, set it
true (with tags) to publish on release.

## Usage

Verify the build on a pull request. Add this file at `.github/workflows/pr.yml`; it is
complete as shown and builds the image without pushing:

```yaml
name: pr
on:
  pull_request:

jobs:
  image:
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v0
    with:
      file: docker/Dockerfile
      tags: myapp:pr-${{ github.event.number }}
```

Push on release. The calling job grants `packages: write`, and the release trigger and
version stay in the caller:

```yaml
name: release
on:
  push:
    tags:
      - "v*"

jobs:
  image:
    permissions:
      contents: read
      packages: write
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v0
    with:
      file: docker/Dockerfile
      push: true
      tags: |
        ghcr.io/${{ github.repository_owner }}/myapp:${{ github.ref_name }}
        ghcr.io/${{ github.repository_owner }}/myapp:latest
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `context` | `.` | Build context. |
| `file` | `Dockerfile` | Path to the Dockerfile. |
| `push` | `false` | Push to the registry. When false the image is built and loaded locally only. |
| `tags` | (required) | Newline-separated image tags. |
| `labels` | (empty) | Newline-separated image labels. |
| `platforms` | (empty) | Target platforms, for example `linux/amd64`. Empty uses the builder default. |
| `registry` | `ghcr.io` | Registry to log in to when pushing. |
| `cache-scope` | (repository) | Buildx GitHub Actions cache scope. |
| `provenance` | `false` | Attach Buildx SLSA provenance (mode=max) to the pushed image. |
| `sbom` | `false` | Attach a software bill of materials to the pushed image. |
| `attest` | `false` | Sign and store a GitHub build provenance attestation for the pushed image. |
| `image-name` | (empty) | Fully qualified image name without a tag, for example `ghcr.io/owner/app`. Required when `attest` is true. |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `REGISTRY_USERNAME` | no | Registry login user. When omitted, the workflow's GitHub identity is used, which authenticates GHCR only. |
| `REGISTRY_PASSWORD` | no | Registry login password or token. When omitted, the automatic `GITHUB_TOKEN` is used, which authenticates GHCR only. |

The defaults push to GHCR with no configuration. For any other registry, pass both secrets:

```yaml
jobs:
  image:
    permissions:
      contents: read
      packages: write
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v0
    with:
      push: true
      registry: registry.example.com
      tags: registry.example.com/team/myapp:1.2.3
    secrets:
      REGISTRY_USERNAME: ${{ secrets.EXAMPLE_REGISTRY_USER }}
      REGISTRY_PASSWORD: ${{ secrets.EXAMPLE_REGISTRY_TOKEN }}
```

## Supply-chain artifacts

Three opt-in inputs make a pushed image verifiable; all of them apply only when `push` is
true, because they bind to the pushed digest:

- `provenance` attaches Buildx SLSA provenance to the image: how it was built, from what
  source, with what parameters.
- `sbom` attaches a software bill of materials: every package and version inside the
  image, so a new CVE is a lookup instead of a rescan.
- `attest` signs a GitHub build provenance attestation binding the image digest to this
  workflow run and repository, and stores it with GitHub and in the registry. Anyone can
  then verify the image came from CI, not from a workstation:

  ```sh
  gh attestation verify oci://ghcr.io/owner/app:1.2.3 --owner owner
  ```

A release push with all three:

```yaml
jobs:
  image:
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v0
    with:
      file: docker/Dockerfile
      push: true
      provenance: true
      sbom: true
      attest: true
      image-name: ghcr.io/${{ github.repository_owner }}/myapp
      tags: |
        ghcr.io/${{ github.repository_owner }}/myapp:${{ github.ref_name }}
```

## Permissions

This block declares no permissions of its own; it inherits the caller's `GITHUB_TOKEN`. Grant
`contents: read` to build (enough for `push: false`), add `packages: write` on the calling
job when `push: true` to GHCR, and add `id-token: write` plus `attestations: write` when
`attest` is true. Keep the calling job's grant minimal: whatever the caller grants is what
this block's steps run with.

## Notes

- `push: false` builds and loads the image locally, for verification on a PR. `push: true`
  logs in to the registry and pushes.
- A multi-platform image cannot be loaded into the local daemon, so `push: false` with more
  than one platform fails fast with a clear message. Push, or verify one platform per call.
- Release specifics such as the version and tag names stay in the caller; this block only
  takes the finished `tags`.
- The Buildx layer cache uses the GitHub Actions cache, scoped to the calling repository
  by default.
