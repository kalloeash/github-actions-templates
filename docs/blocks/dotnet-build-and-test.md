# dotnet-build-and-test

Restore, build, and test a .NET solution or project in one job. The three steps run together
because `dotnet test --no-build` runs against the output of the build step.

## Usage

Add this file to the consuming repository at `.github/workflows/pr.yml`. It is complete as
shown and runs the build and tests on every pull request:

```yaml
name: pr
on:
  pull_request:

jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/dotnet-build-and-test.yml@v1
    with:
      solution: MySolution.sln
```

The SDK version, build configuration, and working directory are optional; `solution` defaults
to the working directory:

```yaml
jobs:
  build-and-test:
    uses: kalloeash/github-actions-templates/.github/workflows/dotnet-build-and-test.yml@v1
    with:
      dotnet-version: "10.0.x"
      solution: src/MyApp.slnx
      configuration: Release
      working-directory: src
```

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `dotnet-version` | `10.0.x` | SDK version passed to actions/setup-dotnet. |
| `solution` | `.` | Solution, project, or directory to build. A `.sln`, `.slnx`, project file, or directory. |
| `configuration` | `Release` | Build configuration. |
| `working-directory` | `.` | Directory the dotnet commands run in. |

## Permissions

Needs `contents: read` only, which is the default. The block reads the source and writes
nothing back.

## Notes

- Restore, build, and test are one job on purpose: the test step runs with `--no-build`
  against the build output, so splitting them would rebuild.
- The test step uses `--logger trx`; the results file is written under the working directory
  if a later step needs to upload it.
