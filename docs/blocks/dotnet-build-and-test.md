# dotnet-build-and-test

Restore, build, and test a .NET solution or project. The three steps run as one job
because `dotnet test --no-build` runs against the output of the build step.

## Usage

```yaml
jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/dotnet-build-and-test.yml@v1
    with:
      dotnet-version: "10.0.x"
      solution: MySolution.sln
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `dotnet-version` | `10.0.x` | SDK version passed to actions/setup-dotnet. |
| `solution` | (empty) | Path to the solution or project to build. Empty builds the working directory. |
| `configuration` | `Release` | Build configuration. |
| `working-directory` | `.` | Directory the dotnet commands run in. |

## Permissions

Needs `contents: read` only, which is the default. The block reads the source and writes
nothing back.

## Notes

- `solution` accepts a `.sln`, a `.slnx`, or a project file.
- The test step uses `--logger trx`; the results file is written under the working
  directory if a later step needs to upload it.
