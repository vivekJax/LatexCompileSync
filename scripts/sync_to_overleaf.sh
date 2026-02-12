#!/usr/bin/env bash
# =============================================================================
# LatexCompileSync: Sync script — push project to Overleaf on save (generic).
# =============================================================================
# Run from project root. Requires .env with OVERLEAF_PROJECT_ID and OVERLEAF_TOKEN.
# Overleaf Git: https://www.overleaf.com/learn/how-to/Git_integration_authentication_tokens
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

[[ -f .env ]] && source .env

OVERLEAF_PROJECT_ID="${OVERLEAF_PROJECT_ID:-}"
OVERLEAF_TOKEN="${OVERLEAF_TOKEN:-}"
OVERLEAF_REMOTE="${OVERLEAF_REMOTE:-origin}"
OVERLEAF_BRANCH_LOCAL="${OVERLEAF_BRANCH_LOCAL:-main}"
OVERLEAF_BRANCH_REMOTE="${OVERLEAF_BRANCH_REMOTE:-master}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository; skipping Overleaf sync."
  exit 0
fi

if [[ -z "$OVERLEAF_PROJECT_ID" || -z "$OVERLEAF_TOKEN" ]]; then
  echo "⚠️ Set OVERLEAF_PROJECT_ID and OVERLEAF_TOKEN in .env (see .env.example)."
  exit 1
fi

# Temporarily set remote URL with token for push
git remote set-url "$OVERLEAF_REMOTE" "https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${OVERLEAF_PROJECT_ID}" 2>/dev/null || true

git add -A
if git diff --staged --quiet; then
  echo "No changes to sync to Overleaf."
else
  git commit -m "Auto-sync to Overleaf"
  if git push "$OVERLEAF_REMOTE" "${OVERLEAF_BRANCH_LOCAL}:${OVERLEAF_BRANCH_REMOTE}"; then
    echo "✅ Synced to Overleaf."
  else
    echo "⚠️ Push failed. Check OVERLEAF_PROJECT_ID and OVERLEAF_TOKEN."
    git remote set-url "$OVERLEAF_REMOTE" "https://git.overleaf.com/${OVERLEAF_PROJECT_ID}" 2>/dev/null || true
    exit 1
  fi
fi

# Remove token from remote URL
git remote set-url "$OVERLEAF_REMOTE" "https://git.overleaf.com/${OVERLEAF_PROJECT_ID}" 2>/dev/null || true
