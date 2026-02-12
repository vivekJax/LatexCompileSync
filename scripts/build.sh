#!/usr/bin/env bash
# =============================================================================
# LatexCompileSync: Build script — compile LaTeX on save (generic).
# =============================================================================
# Run from project root. Uses env vars (or .env): MAIN_TEX, OUTPUT_PDF, TEX_ENGINE.
# Example: MAIN_TEX=thesis.tex OUTPUT_PDF=Thesis.pdf ./scripts/build.sh
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Load .env if present (MAIN_TEX, OUTPUT_PDF, TEX_ENGINE)
[[ -f .env ]] && source .env

MAIN_TEX="${MAIN_TEX:-main.tex}"
OUTPUT_PDF="${OUTPUT_PDF:-}"
TEX_ENGINE="${TEX_ENGINE:-xelatex}"

# Resolve path to engine (allow system PATH or common install locations)
if command -v "$TEX_ENGINE" &>/dev/null; then
  TEX_BIN="$TEX_ENGINE"
elif [[ -x "/Library/TeX/texbin/$TEX_ENGINE" ]]; then
  TEX_BIN="/Library/TeX/texbin/$TEX_ENGINE"
else
  echo "❌ LaTeX engine not found: $TEX_ENGINE"
  exit 1
fi

if [[ ! -f "$MAIN_TEX" ]]; then
  echo "❌ Main file not found: $MAIN_TEX"
  exit 1
fi

echo "Compiling LaTeX ($TEX_ENGINE): $MAIN_TEX"
"$TEX_BIN" -interaction=nonstopmode "$MAIN_TEX" >/dev/null 2>&1
"$TEX_BIN" -interaction=nonstopmode "$MAIN_TEX"

BASE="${MAIN_TEX%.tex}"
if [[ -n "$OUTPUT_PDF" && -f "${BASE}.pdf" ]]; then
  cp -f "${BASE}.pdf" "$OUTPUT_PDF"
  echo "✅ PDF saved as $(pwd)/$OUTPUT_PDF"
elif [[ -f "${BASE}.pdf" ]]; then
  echo "✅ PDF built: $(pwd)/${BASE}.pdf"
else
  echo "❌ ${BASE}.pdf not found after build."
  exit 1
fi
