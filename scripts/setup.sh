#!/usr/bin/env bash
# =============================================================================
# LatexCompileSync: One-command setup — add compile-on-save and Overleaf sync
# to any LaTeX project. Run from the project directory or use --dir.
# =============================================================================
# Usage:
#   bash setup.sh --url https://www.overleaf.com/project/XXXX --token olp_xxx
#   bash setup.sh --url https://www.overleaf.com/project/XXXX --token olp_xxx --dir /path/to/project
#   bash <(curl -sL https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts/setup.sh) --url URL --token TOKEN
# =============================================================================
set -e

REPO_RAW="https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts"
OVERLEAF_URL=""
OVERLEAF_TOKEN=""
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   OVERLEAF_URL="$2"; shift 2 ;;
    --token) OVERLEAF_TOKEN="$2"; shift 2 ;;
    --dir)   TARGET_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --url <overleaf_project_url> --token <overleaf_git_token> [--dir <project_dir>]"
      echo "  --url   e.g. https://www.overleaf.com/project/686be2799dfc5715eab66dfc"
      echo "  --token From Overleaf: Account Settings → Git integration → Generate token"
      echo "  --dir   LaTeX project directory (default: current directory)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$OVERLEAF_URL" || -z "$OVERLEAF_TOKEN" ]]; then
  echo "Error: --url and --token are required."
  echo "Run with --help for usage."
  exit 1
fi

# Resolve target directory
if [[ -n "$TARGET_DIR" ]]; then
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
else
  TARGET_DIR="$(pwd)"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory does not exist: $TARGET_DIR"
  exit 1
fi

# Extract project ID (last path segment of Overleaf project URL)
if [[ "$OVERLEAF_URL" =~ [./]project/([a-f0-9]+)/?$ ]]; then
  PROJECT_ID="${BASH_REMATCH[1]}"
else
  echo "Error: Could not extract project ID from URL: $OVERLEAF_URL"
  echo "Expected form: https://www.overleaf.com/project/<project_id>"
  exit 1
fi

echo "[LatexCompileSync] Setting up in: $TARGET_DIR"
echo "[LatexCompileSync] Overleaf project ID: $PROJECT_ID"
cd "$TARGET_DIR"

# -----------------------------------------------------------------------------
# Detect main .tex file (contains \documentclass)
# -----------------------------------------------------------------------------
MAIN_TEX=""
for candidate in main.tex Main.tex manuscript.tex Manuscript.tex paper.tex Paper.tex; do
  if [[ -f "$candidate" ]]; then
    if grep -q '\\documentclass' "$candidate" 2>/dev/null; then
      MAIN_TEX="$candidate"
      break
    fi
  fi
done
if [[ -z "$MAIN_TEX" ]]; then
  while IFS= read -r -d '' f; do
    if grep -q '\\documentclass' "$f" 2>/dev/null; then
      MAIN_TEX="${f#./}"
      break
    fi
  done < <(find . -name "*.tex" -not -path "./.git/*" -print0 2>/dev/null | sort -z)
fi
if [[ -z "$MAIN_TEX" ]]; then
  MAIN_TEX="main.tex"
  echo "[LatexCompileSync] No .tex file with \\documentclass found; defaulting to main.tex (create it or set MAIN_TEX in .env later)."
else
  echo "[LatexCompileSync] Main .tex file: $MAIN_TEX"
fi

# -----------------------------------------------------------------------------
# Create scripts/ and download or copy build.sh, sync_to_overleaf.sh
# -----------------------------------------------------------------------------
mkdir -p scripts
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [[ -f "${SCRIPT_SOURCE_DIR}/build.sh" && -f "${SCRIPT_SOURCE_DIR}/sync_to_overleaf.sh" ]]; then
  cp -f "${SCRIPT_SOURCE_DIR}/build.sh" scripts/
  cp -f "${SCRIPT_SOURCE_DIR}/sync_to_overleaf.sh" scripts/
  echo "[LatexCompileSync] Copied build.sh and sync_to_overleaf.sh from local repo."
else
  for name in build.sh sync_to_overleaf.sh; do
    if command -v curl &>/dev/null; then
      curl -sL "${REPO_RAW}/${name}" -o "scripts/${name}" || { echo "Failed to download scripts/${name}"; exit 1; }
    else
      echo "Error: curl not found and scripts not in same directory. Install curl or run from LatexCompileSync repo."
      exit 1
    fi
  done
  echo "[LatexCompileSync] Downloaded build.sh and sync_to_overleaf.sh from GitHub."
fi
chmod +x scripts/build.sh scripts/sync_to_overleaf.sh

# -----------------------------------------------------------------------------
# Create .env (never overwrite existing .env; append or create)
# -----------------------------------------------------------------------------
if [[ -f .env ]]; then
  # For each variable: update in place if the line exists, otherwise append
  for pair in "OVERLEAF_PROJECT_ID=$PROJECT_ID" "OVERLEAF_TOKEN=$OVERLEAF_TOKEN" "MAIN_TEX=$MAIN_TEX"; do
    varname="${pair%%=*}"
    if grep -q "^${varname}=" .env 2>/dev/null; then
      sed -i.bak "s|^${varname}=.*|${pair}|" .env && rm -f .env.bak
    else
      echo "$pair" >> .env
    fi
  done
  echo "[LatexCompileSync] Updated .env"
else
  cat > .env << EOF
# LatexCompileSync — do not commit (add .env to .gitignore)
OVERLEAF_PROJECT_ID=$PROJECT_ID
OVERLEAF_TOKEN=$OVERLEAF_TOKEN
MAIN_TEX=$MAIN_TEX
# If you cloned from Overleaf, set: OVERLEAF_BRANCH_LOCAL=master
EOF
  echo "[LatexCompileSync] Created .env"
fi

# -----------------------------------------------------------------------------
# .gitignore: ensure .env and common LaTeX artifacts are ignored
# -----------------------------------------------------------------------------
GITIGNORE_ENTRIES=(
  ".env"
  ".DS_Store"
  "*.aux"
  "*.bbl"
  "*.blg"
  "*.fdb_latexmk"
  "*.fls"
  "*.log"
  "*.out"
  "*.synctex.gz"
  "*.toc"
)
if [[ -f .gitignore ]]; then
  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if ! grep -qFx "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
    fi
  done
  echo "[LatexCompileSync] Updated .gitignore"
else
  printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > .gitignore
  echo "[LatexCompileSync] Created .gitignore"
fi

# -----------------------------------------------------------------------------
# .vscode/settings.json — LaTeX Workshop "Build and Sync" recipe
# -----------------------------------------------------------------------------
mkdir -p .vscode
SETTINGS_FILE=".vscode/settings.json"
if [[ -f "$SETTINGS_FILE" ]] && command -v python3 &>/dev/null; then
  # Merge: add or update only our keys (prefer not to overwrite whole file)
  export MAIN_TEX
  python3 -c '
import json, os
path = ".vscode/settings.json"
with open(path) as f:
    d = json.load(f)
d["latex-workshop.latex.autoBuild.run"] = "onSave"
d["latex-workshop.latex.rootDir"] = "."
d["latex-workshop.latex.mainFile"] = os.environ.get("MAIN_TEX", "main.tex")
d["latex-workshop.latex.tools"] = d.get("latex-workshop.latex.tools") or []
names = [t.get("name") for t in d["latex-workshop.latex.tools"]]
for tool in [{"name": "build", "command": "bash", "args": ["%DIR%/scripts/build.sh"]}, {"name": "sync_to_overleaf", "command": "bash", "args": ["%DIR%/scripts/sync_to_overleaf.sh"]}]:
    if tool["name"] not in names:
        d["latex-workshop.latex.tools"].append(tool)
d["latex-workshop.latex.recipes"] = [{"name": "Build and Sync", "tools": ["build", "sync_to_overleaf"]}]
d["latex-workshop.latex.recipe.default"] = "first"
with open(path, "w") as f:
    json.dump(d, f, indent=2)
'
  echo "[LatexCompileSync] Merged LaTeX Workshop settings into .vscode/settings.json"
else
  cat > "$SETTINGS_FILE" << EOF
{
  "latex-workshop.latex.autoBuild.run": "onSave",
  "latex-workshop.latex.rootDir": ".",
  "latex-workshop.latex.mainFile": "$MAIN_TEX",
  "latex-workshop.latex.tools": [
    { "name": "build", "command": "bash", "args": ["%DIR%/scripts/build.sh"] },
    { "name": "sync_to_overleaf", "command": "bash", "args": ["%DIR%/scripts/sync_to_overleaf.sh"] }
  ],
  "latex-workshop.latex.recipes": [
    { "name": "Build and Sync", "tools": ["build", "sync_to_overleaf"] }
  ],
  "latex-workshop.latex.recipe.default": "first"
}
EOF
  echo "[LatexCompileSync] Created .vscode/settings.json"
fi

# -----------------------------------------------------------------------------
# .vscode/tasks.json — optional manual "Sync to Overleaf" task
# -----------------------------------------------------------------------------
TASKS_FILE=".vscode/tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  cat > "$TASKS_FILE" << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build LaTeX",
      "type": "shell",
      "command": "./scripts/build.sh",
      "options": { "cwd": "${workspaceFolder}" },
      "group": { "kind": "build", "isDefault": true },
      "presentation": { "reveal": "silent", "panel": "shared" },
      "problemMatcher": []
    },
    {
      "label": "Sync to Overleaf",
      "type": "shell",
      "command": "./scripts/sync_to_overleaf.sh",
      "options": { "cwd": "${workspaceFolder}" },
      "group": "none",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    }
  ]
}
EOF
  echo "[LatexCompileSync] Created .vscode/tasks.json"
fi

# -----------------------------------------------------------------------------
# Git: init, remote, fetch and merge from Overleaf
# -----------------------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  git init
  echo "[LatexCompileSync] Initialized git repository."
fi

if ! git remote get-url origin &>/dev/null; then
  git remote add origin "https://git.overleaf.com/${PROJECT_ID}"
  echo "[LatexCompileSync] Added remote origin (Overleaf)."
fi

# Fetch and merge Overleaf content (master) so local has their files
FETCH_URL="https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${PROJECT_ID}"
if GIT_TERMINAL_PROMPT=0 git -c credential.helper= fetch "$FETCH_URL" master 2>&1; then
  if ! git rev-parse -q --verify HEAD &>/dev/null; then
    git merge FETCH_HEAD --allow-unrelated-histories -m "Merge Overleaf project"
    echo "[LatexCompileSync] Merged existing Overleaf project into local repo."
  else
    if ! git merge FETCH_HEAD --allow-unrelated-histories -m "Merge Overleaf project" 2>&1; then
      git merge --abort 2>/dev/null || true
      echo "[LatexCompileSync] WARNING: Merge conflict with Overleaf content. Merge aborted."
      echo "[LatexCompileSync] You can manually merge later: git fetch origin master && git merge FETCH_HEAD --allow-unrelated-histories"
    else
      echo "[LatexCompileSync] Merged existing Overleaf project into local repo."
    fi
  fi
else
  echo "[LatexCompileSync] Could not fetch from Overleaf (empty project or network issue)."
  echo "[LatexCompileSync] You can push later with sync_to_overleaf.sh."
fi

echo ""
echo "Done. Next steps:"
echo "  1. Install the LaTeX Workshop extension in Cursor/VS Code if needed."
echo "  2. Reload the window (Cmd+Shift+P → Developer: Reload Window)."
echo "  3. Edit and save your .tex file — PDF will build and sync to Overleaf automatically."
