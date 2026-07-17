# Releasing

Releases are cut from `main` and follow semver. The changelog is generated from
Conventional Commit messages with [git-cliff](https://git-cliff.org), configured in
[`cliff.toml`](../cliff.toml).

## Versioning

- Full release tags are `vX.Y.Z` and are immutable once published.
- A floating major tag (`vN`, for example `v0`) tracks the latest release in that major
  line. A consumer that pins `@vN` picks up compatible fixes without editing its caller
  file. The floating tag carries no GitHub Release of its own, so it stays movable.
- During `0.x`, minor versions may still break. Pin an exact `@vX.Y.Z` or a commit SHA
  until `v1.0.0`.

## Cutting a release

1. On a branch, regenerate the changelog for the new version and commit it:

   ```sh
   git-cliff --config cliff.toml --tag vX.Y.Z --output CHANGELOG.md
   git add CHANGELOG.md
   git commit -m "chore(release): vX.Y.Z"
   ```

2. Open a pull request, get CI green, and squash-merge it.
3. Tag the resulting commit on `main` and push the tag:

   ```sh
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin vX.Y.Z
   ```

   Version tags are annotated (`-a`), so `git tag -n` and tooling see a proper tag object.
   The floating major tag is the only lightweight tag, moved by the release workflow.

4. The [`.release.yml`](../.github/workflows/.release.yml) workflow runs on the tag. It
   builds the release notes with git-cliff, publishes an immutable GitHub Release, and moves
   the floating major tag (`vN`) to the released commit.
5. The tag push also triggers [`.verify-release.yml`](../.github/workflows/.verify-release.yml),
   which runs every block at the tagged commit against the fixtures. The release is done
   when it is green; a failure opens an issue.

## Notes

- Enable immutable releases in the repository settings (Settings, General) so a published
  release tag cannot be moved or deleted.
- The floating major tag is moved by the workflow through the Git refs API and never
  carries a release, which is what keeps it movable.
