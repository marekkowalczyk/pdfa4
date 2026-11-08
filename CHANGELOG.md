# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-11-08

### Added

- `/Rotate` awareness: orientation and already-A4 checks use displayed size (90°/270° swap width/height)
- `cpdf -upright` before scaling when any page has non-zero rotation
- Real-`cpdf` integration tests (`tests/pdfa4-integration.bats`), skipped when `cpdf` is missing

### Changed

- Version bump to 1.1.0

## [1.0.0] — 2026-11-08

### Added

- Initial release: normalize PDF pages to A4 via `cpdf -scale-to-fit`
- Fit with white pad (aspect ratio preserved); default preserve orientation
- `-p` / `--portrait` and `-l` / `--landscape` force orientation
- Skip rewrite when every page is already A4 (1 pt tolerance)
- Backup to `FILE.bak` by default; `--no-backup` to skip
- Standard suite flags: `-a` / `.`, `-n`, `-v`, `-q`, `--version`, `-h`
- Mock `cpdf` bats suite, Makefile, pre-commit hook

[1.1.0]: https://github.com/marekkowalczyk/pdfa4/releases/tag/v1.1.0
[1.0.0]: https://github.com/marekkowalczyk/pdfa4/releases/tag/v1.0.0
