# Next Session

## Completed last session

- [x] ~~v1.0.0 / v1.1.0 tagged and released; MIT LICENSE; CHANGELOG; topics~~
- [x] ~~`/Rotate` awareness + real-cpdf integration tests~~
- [x] ~~Deferred features + pdfcpu research filed as Issues #1–#7~~

## Immediate

- Nothing blocking. Pick a backlog issue when ready (see below), or leave stable.

## Follow-ups / backlog

Details are in the issues — do not re-derive from chat.

| # | Topic |
|---|--------|
| [#1](https://github.com/marekkowalczyk/pdfa4/issues/1) | `--margin` / fit-to-percentage |
| [#2](https://github.com/marekkowalczyk/pdfa4/issues/2) | `--size` for non-A4 targets |
| [#3](https://github.com/marekkowalczyk/pdfa4/issues/3) | Page range |
| [#4](https://github.com/marekkowalczyk/pdfa4/issues/4) | Fill / crop mode |
| [#5](https://github.com/marekkowalczyk/pdfa4/issues/5) | Safer backup when `.bak` exists |
| [#6](https://github.com/marekkowalczyk/pdfa4/issues/6) | Report-only / audit mode |
| [#7](https://github.com/marekkowalczyk/pdfa4/issues/7) | Spike: replace cpdf with Go **pdfcpu** |

## Current state

- Tool on PATH as `pdfa4`; bats suite includes unit + real-cpdf integration (integration skips if `cpdf` missing).
- Latest GitHub Release is the current line.

## Process notes

- **Release order:** commit LICENSE/CHANGELOG/README first; confirm they are in `HEAD`; then tag and `gh release create`.
- Backlog body lives in GitHub Issues; this file only links.
- Suite wiring for new tools: `pdftools` `install.sh` TOOLS + README table + deps (see pdftools `CONVENTIONS.md`).
- Prefer awk for `cpdf -page-info` parsing; verify `/Rotate` against cpdf page-range semantics before relying on `portrait`/`landscape`.
