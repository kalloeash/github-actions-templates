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

## Permissions

This block declares no permissions of its own; it inherits the caller's `GITHUB_TOKEN`. Grant
`contents: read` to build (enough for `push: false`), and add `packages: write` on the calling
job when `push: true` to GHCR. Keep the calling job's grant minimal: whatever the caller
grants is what this block's steps run with.

## Notes

- `push: false` builds and loads the image locally, for verification on a PR. `push: true`
  logs in to the registry and pushes.
- A multi-platform image cannot be loaded into the local daemon, so `push: false` with more
  than one platform fails fast with a clear message. Push, or verify one platform per call.
- Release specifics such as the version and tag names stay in the caller; this block only
  takes the finished `tags`.
- The Buildx layer cache uses the GitHub Actions cache, scoped to the calling repository
  by default.
