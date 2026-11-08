# After Action Review

Continuous improvement log. Each session ends with a brief review: what went well, what didn't, what to change. This is the POOGI (Process Of Ongoing Improvement) record for this project.

## 2026-11-08 — Session close: v1.1.0 released, backlog in Issues

**What went well:**
- Feature backlog went to **separate informative GitHub Issues** (#1–#7) with `NEXT-SESSION.md` as a link table only — research (pdfcpu) lives in #7, not chat.
- Release packaging matched `pdfclean`: MIT LICENSE, CHANGELOG, topics, annotated tags, GitHub Releases for v1.0.0 and v1.1.0.
- Left `pdftools` unreleased on purpose (suite pointer, not a versioned product).

**What didn't go well:**
- **Near-miss:** tagged `v1.1.0` before `LICENSE`/`CHANGELOG` were committed; had to delete/re-push the tag and recreate the release. Caught before anyone depended on the tag, but the first cut was incomplete.
- Structured `AskQuestion` picker unavailable in this Cursor session; fell back to letter options (user had asked for a picker).

**What we'll do differently:**
- **Release order:** commit LICENSE + CHANGELOG + README links first, verify `git ls-tree HEAD` contains them, *then* `git tag` / `gh release create`.
- Prefer GitHub Issues for deferred features + research; keep `NEXT-SESSION.md` as pointers, not the backlog body.

---

## 2026-11-08 — /Rotate awareness + real-cpdf integration tests

**What went well:**
- Feature interview pruned a long list to two concrete items; shipped both in one pass.
- `cpdf -upright` before `-scale-to-fit` fixes the known cpdf gap (portrait/landscape ranges ignore `/Rotate`).
- Integration suite (5 tests) caught the intended behaviours against real cpdf; unit mocks cover upright failure.

**What didn't go well:**
- Nothing material this round.

**What we'll do differently:**
- When proposing a backend behaviour, verify cpdf's page-range semantics against `/Rotate` early — the manual documents it, and `-prerotate` / `-upright` exist for a reason.

---

## 2026-11-08 — Initial pdfa4

**What went well:**
- Spec locked via short interview (fit, preserve orientation, skip already-A4, portrait/landscape flags, backup-by-default).
- `cpdf -scale-to-fit a4portrait|a4landscape` matches the fit+pad requirement directly.
- Smoke-tested against real cpdf before writing the bats suite.

**What didn't go well:**
- First page-info parser treated empty `CropBox:` lines as `0×0` (extglob trim), so already-A4 files were rewritten. Caught in smoke test; fixed before ship.

**What we'll do differently:**
- Prefer awk for structured `cpdf -page-info` parsing; don't rely on bash extglob for optional fields.
