#!/usr/bin/env bash
# =============================================================================
# LatexCompileSync: One-command setup — add compile-on-save and Overleaf sync
# to any LaTeX project. Run from the project directory or use --dir.
# =============================================================================
# Usage:
#   bash setup.sh --url https://www.overleaf.com/project/XXXX
#   bash setup.sh --url URL --token-file ~/Tokens_API_Kumar/Overleaf.txt --dir /path/to/project
#   bash setup.sh --url URL --token olp_xxx
#   bash <(curl -sL https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts/setup.sh) --url URL
# =============================================================================
set -e

REPO_RAW="https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts"
OVERLEAF_URL=""
OVERLEAF_TOKEN="${OVERLEAF_TOKEN:-}"
TOKEN_FILE="${OVERLEAF_TOKEN_FILE:-}"
TARGET_DIR=""
DEFAULT_TOKEN_FILE="${HOME}/Tokens_API_Kumar/Overleaf.txt"
BACKUP_DIR=".latexcompilesync_backup"

usage() {
  echo "Usage: $0 --url <overleaf_project_url> [options]"
  echo "  --url         e.g. https://www.overleaf.com/project/686be2799dfc5715eab66dfc (required)"
  echo "  --token-file  Path to a file containing the Overleaf Git token (preferred)"
  echo "  --token       Overleaf Git token (Account Settings → Git integration)"
  echo "  --dir         LaTeX project directory (default: current directory)"
  echo ""
  echo "Token resolution order: --token, --token-file, \$OVERLEAF_TOKEN,"
  echo "  \$OVERLEAF_TOKEN_FILE, then ${DEFAULT_TOKEN_FILE} if present."
}

read_token_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Error: Token file not found: $path" >&2
    return 1
  fi
  local tok
  tok="$(grep -v '^[[:space:]]*$' "$path" | head -n 1 | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ -z "$tok" ]]; then
    echo "Error: Token file is empty: $path" >&2
    return 1
  fi
  OVERLEAF_TOKEN="$tok"
}

detect_main_tex() {
  MAIN_TEX=""
  local candidate f
  for candidate in main.tex Main.tex manuscript.tex Manuscript.tex paper.tex Paper.tex jax_main.tex; do
    if [[ -f "$candidate" ]] && grep -q '\\documentclass' "$candidate" 2>/dev/null; then
      MAIN_TEX="$candidate"
      return 0
    fi
  done
  while IFS= read -r -d '' f; do
    if grep -q '\\documentclass' "$f" 2>/dev/null; then
      MAIN_TEX="${f#./}"
      return 0
    fi
  done < <(find . -name "*.tex" -not -path "./.git/*" -not -path "./${BACKUP_DIR}/*" -print0 2>/dev/null | sort -z)
  MAIN_TEX="main.tex"
  return 1
}

backup_path_if_present() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return 0
  fi
  case "$path" in
    .git|.git/*|"$BACKUP_DIR"|"$BACKUP_DIR"/*) return 0 ;;
  esac
  local dest="${BACKUP_DIR}/${path}"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    local i=1
    while [[ -e "${dest}.$i" || -L "${dest}.$i" ]]; do
      i=$((i + 1))
    done
    dest="${dest}.$i"
  fi
  mv "$path" "$dest"
  echo "[LatexCompileSync] Backed up conflicting path: $path → $dest"
}

backup_fetch_conflicts() {
  mkdir -p "$BACKUP_DIR"
  local path
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -e "$path" || -L "$path" ]]; then
      if ! git rev-parse -q --verify HEAD &>/dev/null; then
        backup_path_if_present "$path"
      elif git status --porcelain -- "$path" 2>/dev/null | grep -q '^[?][?]'; then
        backup_path_if_present "$path"
      fi
    fi
  done < <(git ls-tree -r --name-only FETCH_HEAD 2>/dev/null)
  for path in .DS_Store .gitignore .gitattributes .vscode scripts; do
    if [[ -e "$path" || -L "$path" ]]; then
      if ! git rev-parse -q --verify HEAD &>/dev/null; then
        if git ls-tree --name-only FETCH_HEAD 2>/dev/null | grep -qx "$path" \
          || git ls-tree --name-only FETCH_HEAD 2>/dev/null | grep -q "^${path}/"; then
          backup_path_if_present "$path"
        fi
      fi
    fi
  done
}

ensure_gitignore() {
  local GITIGNORE_ENTRIES=(
    ".env"
    ".DS_Store"
    "${BACKUP_DIR}/"
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
    local entry
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
}

upsert_env_var() {
  local varname="$1"
  local value="$2"
  if [[ -f .env ]] && grep -q "^${varname}=" .env 2>/dev/null; then
    sed -i.bak "s|^${varname}=.*|${varname}=${value}|" .env && rm -f .env.bak
  else
    echo "${varname}=${value}" >> .env
  fi
}

write_or_update_env() {
  if [[ ! -f .env ]]; then
    cat > .env << EOF
# LatexCompileSync — do not commit (add .env to .gitignore)
OVERLEAF_PROJECT_ID=$PROJECT_ID
OVERLEAF_TOKEN=$OVERLEAF_TOKEN
MAIN_TEX=$MAIN_TEX
OVERLEAF_BRANCH_LOCAL=$OVERLEAF_BRANCH_LOCAL
OVERLEAF_BRANCH_REMOTE=$OVERLEAF_BRANCH_REMOTE
TEX_ENGINE=xelatex
EOF
    echo "[LatexCompileSync] Created .env"
  else
    upsert_env_var "OVERLEAF_PROJECT_ID" "$PROJECT_ID"
    upsert_env_var "OVERLEAF_TOKEN" "$OVERLEAF_TOKEN"
    upsert_env_var "MAIN_TEX" "$MAIN_TEX"
    upsert_env_var "OVERLEAF_BRANCH_LOCAL" "$OVERLEAF_BRANCH_LOCAL"
    upsert_env_var "OVERLEAF_BRANCH_REMOTE" "$OVERLEAF_BRANCH_REMOTE"
    if ! grep -q "^TEX_ENGINE=" .env 2>/dev/null; then
      echo "TEX_ENGINE=xelatex" >> .env
    fi
    echo "[LatexCompileSync] Updated .env"
  fi
}

install_scripts() {
  mkdir -p scripts
  local SCRIPT_SOURCE_DIR=""
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
  fi
  if [[ -n "$SCRIPT_SOURCE_DIR" \
        && "$SCRIPT_SOURCE_DIR" != /dev/fd* \
        && -f "${SCRIPT_SOURCE_DIR}/build.sh" \
        && -f "${SCRIPT_SOURCE_DIR}/sync_to_overleaf.sh" ]]; then
    cp -f "${SCRIPT_SOURCE_DIR}/build.sh" scripts/
    cp -f "${SCRIPT_SOURCE_DIR}/sync_to_overleaf.sh" scripts/
    perl -pi -e 's/\r$//' scripts/build.sh scripts/sync_to_overleaf.sh 2>/dev/null || true
    echo "[LatexCompileSync] Copied build.sh and sync_to_overleaf.sh from local repo."
    chmod +x scripts/build.sh scripts/sync_to_overleaf.sh
    return 0
  fi
  local name
  for name in build.sh sync_to_overleaf.sh; do
    if command -v curl &>/dev/null; then
      curl -sL "${REPO_RAW}/${name}" | tr -d '\r' > "scripts/${name}" \
        || { echo "Failed to download scripts/${name}"; exit 1; }
    else
      echo "Error: curl not found and scripts not in same directory."
      exit 1
    fi
  done
  echo "[LatexCompileSync] Downloaded build.sh and sync_to_overleaf.sh from GitHub."
  chmod +x scripts/build.sh scripts/sync_to_overleaf.sh
}

configure_vscode() {
  mkdir -p .vscode
  local SETTINGS_FILE=".vscode/settings.json"
  if [[ -f "$SETTINGS_FILE" ]] && command -v python3 &>/dev/null; then
    export MAIN_TEX
    python3 -c '
import json, os
path = ".vscode/settings.json"
with open(path) as f:
    d = json.load(f)
d["latex-workshop.latex.autoBuild.run"] = "onSave"
d["latex-workshop.latex.rootDir"] = "."
d["latex-workshop.latex.mainFile"] = os.environ.get("MAIN_TEX", "main.tex")
tools = d.get("latex-workshop.latex.tools") or []
names = {t.get("name") for t in tools}
for tool in [
    {"name": "build", "command": "bash", "args": ["%DIR%/scripts/build.sh"]},
    {"name": "sync_to_overleaf", "command": "bash", "args": ["%DIR%/scripts/sync_to_overleaf.sh"]},
]:
    if tool["name"] not in names:
        tools.append(tool)
d["latex-workshop.latex.tools"] = tools
recipes = [r for r in (d.get("latex-workshop.latex.recipes") or []) if r.get("name") != "Build and Sync"]
recipes.insert(0, {"name": "Build and Sync", "tools": ["build", "sync_to_overleaf"]})
d["latex-workshop.latex.recipes"] = recipes
d["latex-workshop.latex.recipe.default"] = "first"
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
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

  local TASKS_FILE=".vscode/tasks.json"
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
}

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)        OVERLEAF_URL="$2"; shift 2 ;;
    --token)      OVERLEAF_TOKEN="$2"; shift 2 ;;
    --token-file) TOKEN_FILE="$2"; shift 2 ;;
    --dir)        TARGET_DIR="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$OVERLEAF_URL" ]]; then
  echo "Error: --url is required."
  usage
  exit 1
fi

if [[ -n "$OVERLEAF_TOKEN" ]]; then
  :
elif [[ -n "$TOKEN_FILE" ]]; then
  read_token_file "$TOKEN_FILE"
elif [[ -n "${OVERLEAF_TOKEN_FILE:-}" ]]; then
  read_token_file "$OVERLEAF_TOKEN_FILE"
elif [[ -f "$DEFAULT_TOKEN_FILE" ]]; then
  echo "[LatexCompileSync] Using token file: $DEFAULT_TOKEN_FILE"
  read_token_file "$DEFAULT_TOKEN_FILE"
else
  echo "Error: No Overleaf token found."
  echo "Provide --token-file, --token, \$OVERLEAF_TOKEN, \$OVERLEAF_TOKEN_FILE,"
  echo "or place a token in $DEFAULT_TOKEN_FILE"
  exit 1
fi

if [[ -z "$OVERLEAF_TOKEN" ]]; then
  echo "Error: Overleaf token is empty."
  exit 1
fi

if [[ -n "$TARGET_DIR" ]]; then
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
else
  TARGET_DIR="$(pwd)"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory does not exist: $TARGET_DIR"
  exit 1
fi

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

OVERLEAF_BRANCH_REMOTE="master"
OVERLEAF_BRANCH_LOCAL="master"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  git init
  git checkout -b master 2>/dev/null || git branch -M master 2>/dev/null || true
  echo "[LatexCompileSync] Initialized git repository (branch master)."
fi

if ! git remote get-url origin &>/dev/null; then
  git remote add origin "https://git.overleaf.com/${PROJECT_ID}"
  echo "[LatexCompileSync] Added remote origin (Overleaf)."
else
  echo "[LatexCompileSync] Remote origin already set: $(git remote get-url origin)"
fi

FETCH_URL="https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${PROJECT_ID}"
if GIT_TERMINAL_PROMPT=0 git -c credential.helper= fetch "$FETCH_URL" master 2>&1; then
  if ! git rev-parse -q --verify HEAD &>/dev/null; then
    echo "[LatexCompileSync] Empty local repo — checking out Overleaf master."
    backup_fetch_conflicts
    if git checkout -b master FETCH_HEAD 2>/dev/null || git switch -c master FETCH_HEAD 2>/dev/null; then
      OVERLEAF_BRANCH_LOCAL="master"
      echo "[LatexCompileSync] Checked out Overleaf project on branch master."
    else
      git checkout -f -b master FETCH_HEAD
      OVERLEAF_BRANCH_LOCAL="master"
      echo "[LatexCompileSync] Force-checked out Overleaf project on branch master."
    fi
    if [[ -d "$BACKUP_DIR" ]]; then
      echo "[LatexCompileSync] Local conflicting files (if any) are in: $BACKUP_DIR/"
    fi
  else
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
    OVERLEAF_BRANCH_LOCAL="$CURRENT_BRANCH"
    if git merge FETCH_HEAD --allow-unrelated-histories -m "Merge Overleaf project" 2>&1; then
      echo "[LatexCompileSync] Merged existing Overleaf project into local repo."
    else
      git merge --abort 2>/dev/null || true
      echo "[LatexCompileSync] WARNING: Merge conflict with Overleaf content. Merge aborted."
      echo "[LatexCompileSync] You can manually merge later: git fetch origin master && git merge FETCH_HEAD --allow-unrelated-histories"
    fi
  fi
else
  echo "[LatexCompileSync] Could not fetch from Overleaf (empty project or network issue)."
  echo "[LatexCompileSync] You can push later with sync_to_overleaf.sh."
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo master)"
  OVERLEAF_BRANCH_LOCAL="$CURRENT_BRANCH"
fi

if detect_main_tex; then
  echo "[LatexCompileSync] Main .tex file: $MAIN_TEX"
else
  echo "[LatexCompileSync] No .tex file with \\documentclass found; defaulting to main.tex (create it or set MAIN_TEX in .env later)."
fi

install_scripts
write_or_update_env
ensure_gitignore
configure_vscode

echo ""
echo "Done. Summary:"
echo "  Project:  $TARGET_DIR"
echo "  Overleaf: $PROJECT_ID"
echo "  MAIN_TEX: $MAIN_TEX"
echo "  Branches: local=$OVERLEAF_BRANCH_LOCAL → remote=$OVERLEAF_BRANCH_REMOTE"
if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null || true)" ]]; then
  echo "  Backup:   $BACKUP_DIR/ (local files that conflicted with Overleaf)"
fi
echo ""
echo "Next steps:"
echo "  1. Install the LaTeX Workshop extension in Cursor/VS Code if needed."
echo "  2. Reload the window (Cmd+Shift+P → Developer: Reload Window)."
echo "  3. Edit and save your .tex file — PDF will build and sync to Overleaf automatically."
