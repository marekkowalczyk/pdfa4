# pdfa4

Normalizes PDF pages to A4 in place. Wrapper around `cpdf -scale-to-fit`.

## What it does

- Accepts one or more PDF files; `.` / `--all` / `-a` processes all `*.pdf` / `*.PDF` in the current directory
- Errors if called with no arguments
- Default: preserve each page's orientation (portrait → A4 portrait, landscape → A4 landscape; square → portrait)
- `-p` / `--portrait` and `-l` / `--landscape` force a single orientation (mutually exclusive)
- Leaves already-A4 files byte-identical (1 pt tolerance)
- Writes `FILE.bak` before overwrite unless `--no-backup`
- Warns and skips duplicate filenames

## Structure

Single bash script: `pdfa4`. Symlinked from `/usr/local/bin/pdfa4` (`make install`; `PREFIX` overridable).

Tests: `tests/pdfa4.bats` (mock `cpdf` backend). Run with `make test`.

Pre-commit hook: `hooks/pre-commit`. Install with `make hooks`.

## Dependencies

- `cpdf` (must be installed separately)
- `stat` (macOS `stat -f`), `xattr`, `awk`

## Design decisions

- **Fit, don't fill.** `cpdf -scale-to-fit` preserves aspect ratio and centers; white margins appear when the source aspect ratio differs from A4.
- **Skip rewrite when already A4.** Avoids needless backup/churn for documents that are already correct.
- **Backup by default.** Unlike most siblings; opt out with `--no-backup`. Backup path is `FILE.bak` (replaced if present).
- **Preserve mode uses cpdf page ranges** `portrait` / `landscape`, plus explicit page numbers for squares (cpdf treats equal width/height as neither).
- Follows the Rule of Silence. `--dry-run` previews show by default; `-q` overrides everything but errors. Errors are prefixed `pdfa4:`.
- Same mktemp / chmod / xattr / trap in-place pattern as `pdfstamp` / `pdfrem`.

## Suite

`pdfa4` is part of the [pdftools](https://github.com/marekkowalczyk/pdftools) suite. Cross-tool conventions live in [pdftools/CONVENTIONS.md](https://github.com/marekkowalczyk/pdftools/blob/master/CONVENTIONS.md). **Read it in full before touching any CLI flags or adding features.**

When operating on more than one repo, always `cd /absolute/path && git ...` in a single invocation; never rely on shell cwd persisting across tool calls.
