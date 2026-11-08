# After Action Review

Continuous improvement log. Each session ends with a brief review: what went well, what didn't, what to change. This is the POOGI (Process Of Ongoing Improvement) record for this project.

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
