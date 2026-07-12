# terraform-lint

Lint Terraform configuration with tflint. Installs tflint, initializes the plugins declared in
the repository's `.tflint.hcl`, then lints recursively. tflint catches issues `terraform
validate` does not, such as deprecated syntax, unused declarations, and provider-specific
rules.

## Usage

Add this file to the consuming repository at `.github/workflows/terraform-lint.yml`, or add
the job to an existing pull-request workflow. Pin the tflint version:

```yaml
name: terraform-lint
on:
  pull_request:

jobs:
  lint:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-lint.yml@v0
    with:
      tflint-version: "v0.63.1"
```

The block reads `.tflint.hcl` from the working directory. A minimal one enables the bundled
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
| `tflint-version` | `latest` | tflint version passed to setup-tflint. Pin an exact version for reproducible runs. |
| `working-directory` | `.` | Directory to lint. tflint reads `.tflint.hcl` here and scans recursively. |

## Permissions

Needs `contents: read` only.

## Notes

- `tflint --init` runs first so any plugins declared in `.tflint.hcl` are installed. It uses
  the workflow token to raise the GitHub API rate limit for plugin downloads.
- `tflint --recursive` lints the working directory and every subdirectory in one run.
- The bundled Terraform ruleset needs no download; declaring an external ruleset (for example
  a provider ruleset) works without any change to this block.
