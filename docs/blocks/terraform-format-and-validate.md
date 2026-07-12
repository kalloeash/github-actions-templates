# terraform-format-and-validate

Check formatting and validate Terraform configuration. One job runs `terraform fmt -check`
across the whole tree, then `terraform validate` in each configuration directory. `init` runs
with `-backend=false`, so the block needs no cloud credentials and no access to remote state.

## Usage

Add this file to the consuming repository at `.github/workflows/terraform.yml`, or add the
job to an existing pull-request workflow. Pin the Terraform version and list the directories
that hold a root configuration:

```yaml
name: terraform
on:
  pull_request:

jobs:
  format-and-validate:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-format-and-validate.yml@v0
    with:
      terraform-version: "1.15.8"
      directories: |
        bootstrap
        infra
```

For a single root configuration at the repository root, the defaults are enough:

```yaml
jobs:
  format-and-validate:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-format-and-validate.yml@v0
    with:
      terraform-version: "1.15.8"
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `terraform-version` | `latest` | Terraform version passed to setup-terraform. Pin an exact version for reproducible runs. |
| `directories` | `.` | Newline-separated list of directories to validate, each holding a Terraform configuration. |

## Permissions

Needs `contents: read` only.

## Notes

- `terraform fmt -check -recursive` runs once from the repository root and covers every
  subdirectory, so it is not repeated per directory.
- Each listed directory is validated independently with `terraform -chdir`. All directories
  run even if one fails, so a single job reports every problem at once.
- `init` uses `-backend=false`: validation checks syntax and references, not backend access,
  so no credentials are required.
- Modules validated indirectly through a root configuration do not need their own entry.
