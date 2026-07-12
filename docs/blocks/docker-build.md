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
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v1
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
    uses: kalloeash/github-actions-templates/.github/workflows/docker-build.yml@v1
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
| `cache-scope` | (repo name) | Buildx GitHub Actions cache scope. |

## Permissions

This block declares no permissions of its own; it inherits the caller's `GITHUB_TOKEN`. Grant
`contents: read` to build (enough for `push: false`), and add `packages: write` on the calling
job when `push: true`. The registry login uses the automatic `GITHUB_TOKEN`.

## Notes

- `push: false` builds and loads the image locally, for verification on a PR. `push: true`
  logs in to the registry and pushes.
- Release specifics such as the version and tag names stay in the caller; this block only
  takes the finished `tags`.
- The Buildx layer cache uses the GitHub Actions cache, scoped to the calling repository name
  by default.
