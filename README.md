# pdfa4

Normalize PDF pages to A4 in place. Unequal or non-A4 page sizes are scaled uniformly to fit (aspect ratio preserved) and centered on A4 with white padding.

## Usage

```bash
pdfa4 .                        # normalize all *.pdf / *.PDF in current directory
pdfa4 -a                       # same
pdfa4 report.pdf notes.pdf     # normalize specific files
pdfa4 -p scan.pdf              # force A4 portrait
pdfa4 -l wide.pdf              # force A4 landscape
pdfa4 --no-backup draft.pdf    # skip writing draft.pdf.bak
pdfa4 -n .                     # dry-run: show what would happen, modify nothing
pdfa4 -v .                     # verbose: report each file as it's acted on
pdfa4 -q .                     # quiet: no output unless there's an error
pdfa4 -- -oddly-named.pdf      # use -- to pass filenames starting with -
```

By default each page keeps its orientation (portrait → A4 portrait, landscape → A4 landscape). Square pages are treated as portrait. Page `/Rotate` is respected for orientation and “already A4” checks (90°/270° swap width/height); non-zero rotation is uprighted via cpdf before scaling. Files that are already A4 in displayed size (within 1 pt) are left byte-identical. On overwrite, a `FILE.bak` backup is written unless `--no-backup` is given.

`pdfa4` is silent on success by default (the Rule of Silence) — pass `-v` to see which files were normalized.

## Options

| Flag | Long form | Description |
|------|-----------|-------------|
| `-p` | `--portrait` | Force all pages to A4 portrait |
| `-l` | `--landscape` | Force all pages to A4 landscape |
| | `--no-backup` | Do not write `FILE.bak` before overwriting |
| `.` or `-a` | `--all` | Process all `*.pdf` / `*.PDF` in current directory |
| `-n` | `--dry-run` | Show what would be done without modifying files |
| `-v` | `--verbose` | Report each file as it's acted on (default: silent on success) |
| `-q` | `--quiet` | Suppress all non-error output, overriding `-v` |
| | `--version` | Print version and backend version, then exit |
| `-h` | `--help` | Print help and exit |
| `--` | | End of options; treat remaining args as filenames |

## Installation

```bash
git clone https://github.com/marekkowalczyk/pdfa4.git
cd pdfa4
make install
```

`make install` symlinks `pdfa4` into `$PREFIX/bin` (default `PREFIX=/usr/local`; override with `make install PREFIX=...`). Run `make uninstall` to remove it.

Or install the full [pdftools](https://github.com/marekkowalczyk/pdftools) suite.

## Requirements

- [cpdf](https://www.coherentpdf.com/) (Coherent PDF command-line tools)
- bash

## How it works

Uses `cpdf -scale-to-fit a4portrait` / `a4landscape`, which scales uniformly, centers content, and pads with white.

For each PDF file:

1. Reads page sizes via `cpdf -page-info` (CropBox if set, else MediaBox)
2. Skips the file if every page is already the target A4 size
3. Otherwise scales via cpdf into a temp file in the same directory as the source
4. Copies the original to `FILE.bak` (unless `--no-backup`)
5. Copies file permissions and extended attributes, then swaps the temp over the original
6. Cleans up the temp file on exit, even if interrupted

## Development

```bash
make hooks   # install the pre-commit hook (runs the test suite before every commit)
make test    # run the bats suite
```

Unit tests use a mock `cpdf` binary. `tests/pdfa4-integration.bats` runs against a real `cpdf` and is skipped when it is missing.

## License

MIT
