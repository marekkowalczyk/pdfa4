#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../pdfa4"

# A4 points matching cpdf
A4W=595.276500
A4H=841.891050

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_pdf() {
    local name="${1:-test.pdf}"
    printf '%%PDF-1.4\n1 0 obj\n<</Type /Catalog>>\nendobj\ntrailer\n<</Root 1 0 R>>\n%%%%EOF\n%s\n' \
        "padding padding padding padding padding padding" > "$name"
}

# Install mock cpdf. Behaviour controlled by env:
#   MOCK_PAGES="w,h;w,h;..."   page sizes reported by -page-info (default one A4 portrait)
#   MOCK_SCALE=ok|fail|empty   -scale-to-fit behaviour (default ok → copy input to output)
install_mock() {
    cat > "$BATS_TEST_TMPDIR/cpdf" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-version" ]]; then
    echo "cpdf AGPL Version 2.9.1 (mock)"
    exit 0
fi

if [[ "$1" == "-page-info" ]]; then
    input="$2"
    pages="${MOCK_PAGES:-595.276500,841.891050}"
    n=0
    IFS=';' read -ra ents <<< "$pages"
    for ent in "${ents[@]}"; do
        n=$((n + 1))
        # MOCK_PAGES entries: w,h or w,h,rot
        IFS=',' read -r w h rot <<< "$ent"
        rot=${rot:-0}
        cat <<PAGE
Page $n:
Label: 
MediaBox: 0.000000 0.000000 $w $h
CropBox: 
BleedBox: 
TrimBox: 
ArtBox: 
Rotation: $rot
Annotations: 0
PAGE
    done
    exit 0
fi

# Find -o output and input file
output=""
input=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ "${args[$i]}" == "-o" ]]; then
        output="${args[$((i + 1))]}"
        break
    fi
done
for a in "$@"; do
    case "$a" in
        -*|a4portrait|a4landscape|portrait|landscape|all) ;;
        *)
            if [[ -f "$a" ]]; then input="$a"; break; fi
            ;;
    esac
done

if [[ "$*" == *"-upright"* ]]; then
    case "${MOCK_UPRIGHT:-ok}" in
        fail)  exit 1 ;;
        *)     cp -- "$input" "$output"; exit 0 ;;
    esac
fi

if [[ "$*" == *"-scale-to-fit"* ]]; then
    case "${MOCK_SCALE:-ok}" in
        fail)  exit 1 ;;
        empty) : > "$output"; exit 0 ;;
        *)     cp -- "$input" "$output"; exit 0 ;;
    esac
fi

# passthrough copy
[[ -n "$input" && -n "$output" ]] && cp -- "$input" "$output"
exit 0
EOF
    chmod +x "$BATS_TEST_TMPDIR/cpdf"
    export PATH="$BATS_TEST_TMPDIR:$PATH"
}

setup() {
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir -p "$WORK"
    cd "$WORK"
    unset MOCK_PAGES MOCK_SCALE MOCK_UPRIGHT
    install_mock
}

# ---------------------------------------------------------------------------
# --help / --version
# ---------------------------------------------------------------------------

@test "--help exits 0 and prints usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "-h is alias for --help" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--version prints pdfa4 and cpdf version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"pdfa4"* ]]
    [[ "$output" == *"cpdf"* ]]
}

# ---------------------------------------------------------------------------
# Argument errors
# ---------------------------------------------------------------------------

@test "no args exits 1 with prefixed error" {
    run "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"pdfa4:"* ]]
}

@test "unknown option exits 1 with prefixed error" {
    run "$SCRIPT" --notaflag
    [ "$status" -eq 1 ]
    [[ "$output" == *"pdfa4:"* ]]
}

@test "--portrait and --landscape together exits 1" {
    make_pdf a.pdf
    run "$SCRIPT" -p -l a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot combine"* ]]
}

@test "--all with explicit filenames exits 1" {
    make_pdf a.pdf
    run "$SCRIPT" --all a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot combine"* ]]
}

@test "--all with no PDFs exits 1" {
    run "$SCRIPT" --all
    [ "$status" -eq 1 ]
    [[ "$output" == *"no PDF files"* ]]
}

@test "missing file exits 1 and says skipping" {
    run "$SCRIPT" ghost.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found, skipping"* ]]
}

@test "duplicate filename warned and processed once" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -v --no-backup a.pdf a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"more than once"* ]]
    [ "$(echo "$output" | grep -c "normalized")" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Core behavior
# ---------------------------------------------------------------------------

@test "already A4 leaves file byte-identical and creates no backup" {
    export MOCK_PAGES="${A4W},${A4H}"
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" a.pdf
    [ "$status" -eq 0 ]
    cmp a.pdf orig.pdf
    [ ! -e a.pdf.bak ]
}

@test "already A4 landscape leaves file untouched" {
    export MOCK_PAGES="${A4H},${A4W}"
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" -v a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"already A4"* ]]
    cmp a.pdf orig.pdf
}

@test "non-A4 is normalized in place and backed up by default" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    echo 'original-bytes' > a.pdf
    run "$SCRIPT" a.pdf
    [ "$status" -eq 0 ]
    [ -f a.pdf.bak ]
    [[ "$(cat a.pdf.bak)" == *"original-bytes"* ]]
}

@test "--no-backup skips .bak" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 0 ]
    [ ! -e a.pdf.bak ]
}

@test "-p forces portrait path (still rewrites non-A4)" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -p --no-backup -v a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"normalized"* ]]
}

@test "-l forces landscape path" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -l --no-backup -v a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"normalized"* ]]
}

@test "empty cpdf output is rejected, original kept, exit 1" {
    export MOCK_PAGES="612,792"
    export MOCK_SCALE=empty
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"failed to process"* ]]
    cmp a.pdf orig.pdf
}

@test "cpdf scale failure keeps original and exits 1" {
    export MOCK_PAGES="612,792"
    export MOCK_SCALE=fail
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"pdfa4:"* ]]
    cmp a.pdf orig.pdf
}

@test "file permissions are preserved" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    chmod 640 a.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 0 ]
    [ "$(stat -f%Lp a.pdf)" = "640" ]
}

@test "extended attributes are preserved" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    xattr -w com.test.tag hello a.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 0 ]
    [ "$(xattr -p com.test.tag a.pdf)" = "hello" ]
}

@test "no temp files left behind on success" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ -z "$(ls -A | grep '^\.pdfa4\.')" ]
}

@test "filename starting with - works after --" {
    export MOCK_PAGES="612,792"
    make_pdf ./-odd.pdf
    run "$SCRIPT" --no-backup -- -odd.pdf
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Batch mode
# ---------------------------------------------------------------------------

@test "--all processes every *.pdf and *.PDF" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf; make_pdf B.PDF
    run "$SCRIPT" --all --no-backup
    [ "$status" -eq 0 ]
}

@test "'.' is equivalent to --all" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" . --no-backup
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Verbosity (Rule of Silence)
# ---------------------------------------------------------------------------

@test "silent by default on success" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "silent by default when already A4" {
    export MOCK_PAGES="${A4W},${A4H}"
    make_pdf a.pdf
    run "$SCRIPT" a.pdf
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "--verbose reports normalization" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" --verbose --no-backup a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"a.pdf: normalized to A4"* ]]
}

@test "--quiet overrides --verbose" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -v -q --no-backup a.pdf
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "--quiet does not silence errors" {
    export MOCK_SCALE=fail
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -q --no-backup a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"pdfa4:"* ]]
}

# ---------------------------------------------------------------------------
# Dry run
# ---------------------------------------------------------------------------

@test "--dry-run reports and modifies nothing, no backup" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" --dry-run a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run] would normalize"* ]]
    cmp a.pdf orig.pdf
    [ ! -e a.pdf.bak ]
}

@test "-n already A4 reports would leave untouched" {
    export MOCK_PAGES="${A4W},${A4H}"
    make_pdf a.pdf
    run "$SCRIPT" -n a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run] already A4"* ]]
}

@test "--quiet suppresses --dry-run output" {
    export MOCK_PAGES="612,792"
    make_pdf a.pdf
    run "$SCRIPT" -n -q a.pdf
    [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# /Rotate awareness
# ---------------------------------------------------------------------------

@test "A4 portrait MediaBox with /Rotate 90 is already A4 (effective landscape)" {
    # Box is A4P; rot 90 → displayed A4L → leave untouched, no backup
    export MOCK_PAGES="${A4W},${A4H},90"
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" -v a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"already A4"* ]]
    cmp a.pdf orig.pdf
    [ ! -e a.pdf.bak ]
}

@test "US Letter with /Rotate 90 is normalized (effective landscape)" {
    export MOCK_PAGES="612,792,90"
    make_pdf a.pdf
    run "$SCRIPT" -v --no-backup a.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"normalized"* ]]
}

@test "upright failure keeps original and exits 1" {
    export MOCK_PAGES="612,792,90"
    export MOCK_UPRIGHT=fail
    make_pdf a.pdf
    cp a.pdf orig.pdf
    run "$SCRIPT" --no-backup a.pdf
    [ "$status" -eq 1 ]
    [[ "$output" == *"failed to process"* ]]
    cmp a.pdf orig.pdf
}
