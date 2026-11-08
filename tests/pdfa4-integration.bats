#!/usr/bin/env bats
# Integration tests against a real cpdf. Skipped when cpdf is missing.

SCRIPT="$BATS_TEST_DIRNAME/../pdfa4"
A4W=595.276500
A4H=841.891050

setup() {
    if ! command -v cpdf >/dev/null 2>&1; then
        skip "cpdf not installed"
    fi
    # Ensure we hit the real cpdf, not a leftover mock from another suite
    if cpdf -version 2>&1 | grep -q '(mock)'; then
        skip "cpdf on PATH is a mock"
    fi
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir -p "$WORK"
    cd "$WORK"
}

mediabox() {
    cpdf -page-info "$1" 2>/dev/null | awk -v p="$2" '
        /^Page / { cur = $2 + 0 }
        /^MediaBox:/ && cur == p { print $2, $3, $4, $5; exit }
    '
}

rotation() {
    cpdf -page-info "$1" 2>/dev/null | awk -v p="$2" '
        /^Page / { cur = $2 + 0 }
        /^Rotation:/ && cur == p { print $2 + 0; exit }
    '
}

approx_a4_portrait() {
    local box=$1
    set -- $box
    awk -v llx="$1" -v lly="$2" -v urx="$3" -v ury="$4" -v aw="$A4W" -v ah="$A4H" 'BEGIN {
        w = urx - llx; h = ury - lly
        dw = w - aw; if (dw < 0) dw = -dw
        dh = h - ah; if (dh < 0) dh = -dh
        exit !(dw <= 1.0 && dh <= 1.0)
    }'
}

approx_a4_landscape() {
    local box=$1
    set -- $box
    awk -v llx="$1" -v lly="$2" -v urx="$3" -v ury="$4" -v aw="$A4W" -v ah="$A4H" 'BEGIN {
        w = urx - llx; h = ury - lly
        dw = w - ah; if (dw < 0) dw = -dw
        dh = h - aw; if (dh < 0) dh = -dh
        exit !(dw <= 1.0 && dh <= 1.0)
    }'
}

@test "real cpdf: mixed Letter + A4P + A4L → all A4, orientation preserved" {
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize a4portrait -o a4p.pdf
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize usletterportrait -o letter.pdf
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize a4landscape -o a4l.pdf
    cpdf a4p.pdf letter.pdf a4l.pdf -o mixed.pdf

    run "$SCRIPT" --no-backup mixed.pdf
    [ "$status" -eq 0 ]

    approx_a4_portrait "$(mediabox mixed.pdf 1)"
    approx_a4_portrait "$(mediabox mixed.pdf 2)"
    approx_a4_landscape "$(mediabox mixed.pdf 3)"
}

@test "real cpdf: already A4 left byte-identical" {
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize a4portrait -o a4.pdf
    cp a4.pdf orig.pdf
    run "$SCRIPT" a4.pdf
    [ "$status" -eq 0 ]
    cmp a4.pdf orig.pdf
    [ ! -e a4.pdf.bak ]
}

@test "real cpdf: Letter /Rotate 90 → A4 landscape, Rotation 0" {
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize usletterportrait -o letter.pdf
    cpdf -rotate 90 letter.pdf -o letter90.pdf

    run "$SCRIPT" --no-backup letter90.pdf
    [ "$status" -eq 0 ]

    approx_a4_landscape "$(mediabox letter90.pdf 1)"
    [ "$(rotation letter90.pdf 1)" = "0" ]
}

@test "real cpdf: A4 portrait /Rotate 90 left untouched (already A4)" {
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize a4portrait -o a4.pdf
    cpdf -rotate 90 a4.pdf -o a4r.pdf
    cp a4r.pdf orig.pdf

    run "$SCRIPT" -v a4r.pdf
    [ "$status" -eq 0 ]
    [[ "$output" == *"already A4"* ]]
    cmp a4r.pdf orig.pdf
}

@test "real cpdf: -p forces A4 portrait on landscape Letter" {
    cpdf -create-pdf -create-pdf-pages 1 -create-pdf-papersize usletterlandscape -o letterL.pdf
    run "$SCRIPT" -p --no-backup letterL.pdf
    [ "$status" -eq 0 ]
    approx_a4_portrait "$(mediabox letterL.pdf 1)"
}
