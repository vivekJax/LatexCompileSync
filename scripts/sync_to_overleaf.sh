#!/usr/bin/env bash
# =============================================================================
# LatexCompileSync: Sync script — push project to Overleaf on save (generic).
# =============================================================================
# Run from project root. Requires .env with OVERLEAF_PROJECT_ID and OVERLEAF_TOKEN.
# Overleaf Git: https://www.overleaf.com/learn/how-to/Git_integration_authentication_tokens
# =============================================================================
set -e
echo "[Overleaf sync] Starting..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
echo "[Overleaf sync] Project root: $PROJECT_ROOT"

# Load .env if present
[[ -f .env ]] && source .env

OVERLEAF_PROJECT_ID="${OVERLEAF_PROJECT_ID:-}"
OVERLEAF_TOKEN="${OVERLEAF_TOKEN:-}"
OVERLEAF_BRANCH_LOCAL="${OVERLEAF_BRANCH_LOCAL:-main}"
OVERLEAF_BRANCH_REMOTE="${OVERLEAF_BRANCH_REMOTE:-master}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[Overleaf sync] Not a git repository — skipping."
  exit 0
fi

if [[ -z "$OVERLEAF_PROJECT_ID" || -z "$OVERLEAF_TOKEN" ]]; then
  echo "[Overleaf sync] ERROR: OVERLEAF_PROJECT_ID or OVERLEAF_TOKEN not set in .env"
  exit 1
fi

# Build the push URL with the token embedded.
# We push directly to this URL instead of modifying the remote, which avoids
# leaving the token in .git/config if the script is interrupted.
PUSH_URL="https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${OVERLEAF_PROJECT_ID}"

# Stage tracked and new files, respecting .gitignore.
git add -A

if git diff --staged --quiet; then
  echo "[Overleaf sync] No changes to push."
  exit 0
fi

git commit -m "Auto-sync to Overleaf"
echo "[Overleaf sync] Pushing to Overleaf..."

# GIT_TERMINAL_PROMPT=0  — prevents Git from opening an interactive prompt.
# credential.helper=     — disables the system credential helper (e.g. macOS
#                          Keychain) so that Git uses the token in PUSH_URL
#                          instead of trying to look up / store credentials.
if GIT_TERMINAL_PROMPT=0 git -c credential.helper= push "$PUSH_URL" "${OVERLEAF_BRANCH_LOCAL}:${OVERLEAF_BRANCH_REMOTE}" 2>&1; then
  echo "[Overleaf sync] ✅ Done — Overleaf updated."
else
  echo "[Overleaf sync] ❌ Push failed."
  echo "[Overleaf sync] Check that OVERLEAF_PROJECT_ID and OVERLEAF_TOKEN in .env are correct."
  echo "[Overleaf sync] Also check that Overleaf is not rejecting the push (invalid file paths, etc.)."
  exit 1
fi
