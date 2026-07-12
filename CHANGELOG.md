# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
