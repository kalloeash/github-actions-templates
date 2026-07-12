# precommit-run

Run the calling repository's pre-commit hooks in CI, so the same checks run locally and in
the pipeline. A thin wrapper that installs pre-commit with pip and runs it, with the hook
environments cached on the config hash.

## Usage

Add this file to the consuming repository at `.github/workflows/pr.yml`. It is complete as
shown and runs the repository's hooks on every pull request:

```yaml
name: pr
on:
  pull_request:

jobs:
  pre-commit:
    uses: kalloeash/github-actions-templates/.github/workflows/precommit-run.yml@v0
```

Point at a non-default config or Python version when needed:

```yaml
jobs:
  pre-commit:
    uses: kalloeash/github-actions-templates/.github/workflows/precommit-run.yml@v0
    with:
      python-version: "3.13"
      config: .pre-commit-config.yaml
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `python-version` | `3.13` | Python version passed to actions/setup-python. |
| `config` | `.pre-commit-config.yaml` | pre-commit configuration file. |

## Permissions

Needs `contents: read` only.

## Notes

- Runs `pre-commit run --all-files` against the calling repository's configuration.
- Supports hooks whose environments pre-commit manages itself (`language: python`, `node`,
  `golang`, and so on). Hooks declared `language: system` call tools that must already
  exist on the runner, and a caller cannot install extra tools into a called workflow's
  job, so configurations that rely on system tools beyond the standard runner image fail
  here. A repository with such hooks keeps its own pre-commit job that installs those
  tools first.
- Uses pip directly rather than the upstream pre-commit action, which is in maintenance mode.
