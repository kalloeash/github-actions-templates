# terraform-format-validate-lint

The standard quality gate for a Terraform project in one job: `terraform fmt -check`,
`terraform validate` per root configuration, and `tflint`. One block, like
`node-build-and-test` and `dotnet-build-and-test`, so every Terraform repository runs the same
three checks and cannot drift apart. `validate` runs with `init -backend=false`, so the block
needs no cloud credentials and no access to remote state.

## Usage

Add this file to the consuming repository at `.github/workflows/terraform.yml`, or add the
job to an existing pull-request workflow. List the root configuration directories to
validate:

```yaml
name: terraform
on:
  pull_request:

jobs:
  check:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-format-validate-lint.yml@v0
    with:
      directories: |
        bootstrap
        infra
```

The tool version defaults are pinned in the block and bumped centrally. A project that
needs a specific version passes it explicitly:

```yaml
jobs:
  check:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-format-validate-lint.yml@v0
    with:
      terraform-version: "1.13.4"
      tflint-version: "v0.61.0"
```

tflint reads `.tflint.hcl` from the repository root. A minimal one enables the bundled
Terraform ruleset:

```hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `terraform-version` | `1.15.8` | Terraform version passed to setup-terraform. Pinned in the block, bumped centrally; override to match your project. |
| `tflint-version` | `v0.63.1` | tflint version passed to setup-tflint. Pinned in the block, bumped centrally; override to match your project. |
| `directories` | `.` | Newline-separated list of root configuration directories to validate. |

## Permissions

Needs `contents: read` only.

## Notes

- The checks run in order (`fmt`, then `validate`, then `tflint`) in a single job, so the run
  stops at the first failure, the same way the Node and .NET gates do.
- `fmt -check -recursive` and `tflint --recursive` cover the whole tree, so subdirectories and
  modules are formatted and linted without their own entry.
- `validate` runs per directory in `directories`, because it initializes providers against a
  root configuration. A module validated through a root does not need its own entry.
- `init` uses `-backend=false`: validation checks syntax and references, not backend access,
  so no credentials are required.
- Commit `.terraform.lock.hcl` in each root configuration. `init` respects a committed
  lockfile, so validation runs against the provider versions the project has locked instead
  of whatever is newest.
- `tflint --init` uses the workflow token to raise the GitHub API rate limit for plugin
  downloads. The bundled Terraform ruleset needs no download, and an external ruleset works
  with no change to this block.
