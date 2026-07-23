#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Koen Van Caekenberghe (koen.vancaekenberghe@chipdesign.be), ChipDesign B.V., 07.2026
# Build report.pdf from report.md via pandoc + LaTeX (pure LaTeX, no HTML/CSS).
#
# Requirements: pandoc and a LaTeX engine. The first engine found on PATH is
# used (tectonic, xelatex, lualatex, pdflatex); override with LATEX_ENGINE.
# A unicode-capable engine (tectonic/xelatex/lualatex) is recommended: the
# text uses µ, →, × etc. and sets the main font via fontspec.
set -euo pipefail
cd "$(dirname "$0")"

if [ -z "${LATEX_ENGINE:-}" ]; then
    for e in tectonic xelatex lualatex pdflatex; do
        if command -v "$e" >/dev/null 2>&1; then LATEX_ENGINE="$e"; break; fi
    done
fi
[ -n "${LATEX_ENGINE:-}" ] || { echo "ERROR: no LaTeX engine found (tried tectonic/xelatex/lualatex/pdflatex)" >&2; exit 1; }

# standalone LaTeX source (for inspection / manual builds)
pandoc report.md --standalone -o report.tex

# PDF
pandoc report.md --pdf-engine="$LATEX_ENGINE" -o report.pdf

echo "built: $(pwd)/report.pdf (engine: $LATEX_ENGINE; report.tex alongside)"
