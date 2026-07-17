# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-07-17

### Added

- Add security-iac-scan workflow (#40)

## [0.4.0] - 2026-07-17

### Added

- Add self-tests that run each block against a fixture project (#25)

### Changed

- Bump actions/setup-node from 6.4.0 to 7.0.0 (#27)
- Bump actions/setup-dotnet from 5.4.0 to 6.0.0 (#28)
- Bump eslint from 9.39.5 to 10.7.0 in /tests/node (#29)
- Bump vitest from 3.2.7 to 4.1.10 in /tests/node (#30)
- Bump @eslint/js from 9.39.5 to 10.0.1 in /tests/node (#31)
- Bump xunit from 2.9.2 to 2.9.3 (#34)
- Bump Microsoft.NET.Test.Sdk from 17.12.0 to 18.8.1 (#33)
- Bump xunit.runner.visualstudio from 2.8.2 to 3.1.5 (#35)
- Group dependabot minor and patch updates (#37)

### Fixed

- Pin runner images and terraform tool version defaults (#36)

## [0.3.0] - 2026-07-12

### Added

- Add security-secret-scan workflow (#19)
- Add terraform-format-and-validate workflow (#20)
- Add terraform-lint workflow (#21)

### Changed

- Consolidate the terraform blocks into one quality gate (#22)

### Fixed

- Repair example pins, catalog drift, and internal naming (#17)
- Harden the blocks and the catalog's own workflows (#18)

## [0.2.0] - 2026-07-12

### Added

- Add node-build-and-test workflow (#14)

## [0.1.2] - 2026-07-12

### Fixed

- Let docker-build inherit caller permissions (#12)

## [0.1.1] - 2026-07-12

### Fixed

- Correct floating-major tag existence check in release workflow (#10)

## [0.1.0] - 2026-07-12

### Added

- Add dotnet-build-and-test workflow (#2)
- Add precommit-run workflow (#4)
- Add docker-build workflow (#5)
- Add owasp-dependency-scan workflow (#6)
- Add trivy-image-scan workflow (#7)

### Changed

- Initialize repository
- Repository foundation (#1)
- Prefix security scanners and group the catalog by category (#8)
