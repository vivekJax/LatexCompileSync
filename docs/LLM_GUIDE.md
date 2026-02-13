# LatexCompileSync — Integration guide for LLMs and developers

This document gives **step-by-step instructions** so an LLM or developer can integrate LatexCompileSync into **any** LaTeX project without tying it to a specific paper or Overleaf project. The tooling is generic and config-driven.

---

## 1. Purpose of this repo

- **LatexCompileSync** provides two behaviors:
  1. **Automated compile**: Build the project's main `.tex` file when sources change (e.g. on save).
  2. **Automated Overleaf sync**: Commit and push the project to an Overleaf Git remote when sources change (e.g. on save).

- This repo contains **only** scripts, example configs, and docs. **No LaTeX source** and **no Overleaf content** live here. The user's LaTeX project and Overleaf project are separate; this repo is copied or referenced from the user's project.

---

## 2. File layout (what to copy into a LaTeX project)

```
LatexCompileSync/
├── README.md
├── docs/
│   └── LLM_GUIDE.md          (this file)
├── scripts/
│   ├── build.sh              → copy to <project>/scripts/build.sh
│   └── sync_to_overleaf.sh   → copy to <project>/scripts/sync_to_overleaf.sh
├── .vscode/
│   ├── tasks.json.example    → copy to <project>/.vscode/tasks.json (optional)
│   └── settings.json.example → copy to <project>/.vscode/settings.json
├── .env.example              → copy to <project>/.env and fill in secrets
└── LICENSE
```

The **LaTeX project root** is the directory that contains the main `.tex` file and (optionally) `scripts/`, `.vscode/`, and `.env`. Both scripts assume they are under `<project>/scripts/` and `cd` to `<project>` automatically.

---

## 3. Script contracts

### 3.1 `scripts/build.sh`

- **Invocation**: Run from anywhere; the script resolves `SCRIPT_DIR` and then `cd`s to `SCRIPT_DIR/..` (project root).
- **Environment / .env** (all optional):
  - `MAIN_TEX` — path to main `.tex` (default: `main.tex`).
  - `OUTPUT_PDF` — if set, after a successful build the script copies `<MAIN_TEX base>.pdf` to this path (e.g. a fixed deliverable name).
  - `TEX_ENGINE` — engine name (default: `xelatex`). Typical: `xelatex`, `pdflatex`, `lualatex`.
- **Behavior**: Runs the LaTeX engine twice on `MAIN_TEX`, then optionally copies the PDF to `OUTPUT_PDF`. Exits non-zero on missing file or build failure.
- **Paths**: All paths are relative to the **project root** after the script's `cd`.

### 3.2 `scripts/sync_to_overleaf.sh`

- **Invocation**: Run from anywhere; same as `build.sh`, it `cd`s to the project root.
- **Environment / .env** (required for push):
  - `OVERLEAF_PROJECT_ID` — Overleaf project ID (from URL `https://www.overleaf.com/project/<ID>`).
  - `OVERLEAF_TOKEN` — Overleaf Git token (from Account Settings → Git integration).
  - Optional: `OVERLEAF_BRANCH_LOCAL` (default: `main`), `OVERLEAF_BRANCH_REMOTE` (default: `master`).
- **Behavior**: If not in a git repo, exits 0. Otherwise loads `.env`, stages all changes (respecting `.gitignore`), commits with message `"Auto-sync to Overleaf"`, and pushes. The token is embedded directly in the push URL and **never stored** in `.git/config`. Exits non-zero if token/ID missing or push fails.
- **Important**: The **user's** LaTeX project must already have `git init` and `git remote add origin https://git.overleaf.com/<OVERLEAF_PROJECT_ID>`. This repo does not create the Overleaf project or remote.

---

## 4. Integrating into a new LaTeX project (checklist for LLMs)

> **Read this entire section before generating any files.** Several of the
> bugs below are easy to introduce and hard to diagnose.

1. **Create `scripts/` in the LaTeX project** and add:
   - `build.sh`
   - `sync_to_overleaf.sh`  
   Make them executable: `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`.

2. **Create or update `.env`** in the project root (**do not commit secrets**; add `.env` to `.gitignore`):
   - `OVERLEAF_PROJECT_ID=<from Overleaf project URL>`
   - `OVERLEAF_TOKEN=<from Overleaf account settings>`
   - Optional: `MAIN_TEX=...`, `OUTPUT_PDF=...`, `TEX_ENGINE=...` for `build.sh`.

3. **Determine the local branch name.** If the project was cloned from Overleaf, the local branch is typically `master`. Add `OVERLEAF_BRANCH_LOCAL=master` to `.env`. If you ran `git init`, the default may be `main` — check with `git branch`.

4. **Ensure the project is a git repo** and has the Overleaf remote:
   ```bash
   git init   # if needed
   git remote add origin https://git.overleaf.com/<OVERLEAF_PROJECT_ID>
   ```

5. **Set up `.gitignore`** so that only files you want on Overleaf are tracked. Add:
   ```gitignore
   .env
   .DS_Store
   *.aux
   *.bbl
   *.blg
   *.log
   *.out
   *.toc
   *.synctex.gz
   ```
   Also ignore any **local-only** directories or files (e.g. presentations,
   supporting materials) that should NOT appear on Overleaf. Overleaf will
   **reject** pushes that contain paths it considers invalid (e.g. folder
   names ending in a space, certain special characters).

6. **Add or copy `.vscode/settings.json`** using the recommended Option A
   (LaTeX Workshop recipe chain):

   ```jsonc
   {
     "latex-workshop.latex.autoBuild.run": "onSave",
     "latex-workshop.latex.rootDir": ".",
     "latex-workshop.latex.mainFile": "main.tex",
     "latex-workshop.latex.tools": [
       {
         "name": "build",
         "command": "bash",
         "args": ["%DIR%/scripts/build.sh"]
       },
       {
         "name": "sync_to_overleaf",
         "command": "bash",
         "args": ["%DIR%/scripts/sync_to_overleaf.sh"]
       }
     ],
     "latex-workshop.latex.recipes": [
       { "name": "Build and Sync", "tools": ["build", "sync_to_overleaf"] }
     ],
     "latex-workshop.latex.recipe.default": "first"
   }
   ```

   This chains build → sync as a single LaTeX Workshop recipe. **No extra
   extension is needed** — only LaTeX Workshop.

7. **Optionally add `.vscode/tasks.json`** for manual sync:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Sync to Overleaf",
         "type": "shell",
         "command": "./scripts/sync_to_overleaf.sh",
         "options": { "cwd": "${workspaceFolder}" },
         "presentation": { "reveal": "always", "panel": "shared" },
         "problemMatcher": []
       }
     ]
   }
   ```

8. **Remind the user** to:
   - Install the **LaTeX Workshop** extension.
   - Run **Developer: Reload Window** after settings changes.
   - Check the **LaTeX Workshop** output panel after saving to confirm sync.

---

## 5. Known pitfalls (bugs previously encountered)

> **LLMs: read this section carefully.** These are real bugs that caused
> hours of debugging.

### 5.1 macOS Keychain intercepts git push (`failed to get: -50`)

**Problem**: On macOS, git's credential helper (Keychain) tries to look up
credentials for `git.overleaf.com`, fails with `failed to get: -50` /
`could not read Username`, and the push never reaches Overleaf — even
though the token is in the remote URL.

**Fix**: The sync script now pushes directly to a URL with the token
embedded and disables the credential helper for that command:
```bash
GIT_TERMINAL_PROMPT=0 git -c credential.helper= push "$PUSH_URL" ...
```

**Do not** use `git remote set-url` to temporarily embed the token. If the
script is interrupted, the token stays in `.git/config`.

### 5.2 Run on Save extension — wrong config key and wrong command type

**Problem**: The `emeraldwalk.RunOnSave` config key (with capital letters)
is not recognized by the extension. The correct key is lowercase:
`emeraldwalk.runonsave`.

Additionally, `"cmd"` runs a **shell command** via `child_process.exec`,
not a VS Code command. Using `"cmd": "workbench.action.tasks.runTask"` runs
a nonexistent shell binary and silently fails.

The extension also does **not** support an `"args"` property on command
objects — everything must go in `"cmd"`.

**Fix**: Use the correct lowercase key and a real shell command:
```jsonc
"emeraldwalk.runonsave": {
  "commands": [
    {
      "match": "\\.(tex|sty|bib)$",
      "cmd": "cd \"${workspaceFolder}\" && bash ./scripts/sync_to_overleaf.sh",
      "autoShowOutputPanel": "always"
    }
  ]
}
```

**Better fix**: Skip Run on Save entirely and use the LaTeX Workshop recipe
chain (Option A in `settings.json.example`). This requires zero extra
extensions.

### 5.3 Overleaf rejects pushes with invalid file paths

**Problem**: If `git add -A` stages files with paths that Overleaf
considers invalid (e.g. folder names ending in a space like
`"KL Roadmap /file.pdf"`), the entire push is rejected with
`remote: error: invalid files`.

**Fix**: Set up `.gitignore` in the user's project to exclude any
non-LaTeX files, local assets, presentations, etc., before any commit.
The sync script runs `git add -A` which respects `.gitignore`.

### 5.4 `OVERLEAF_BRANCH_LOCAL` defaults to `main` but Overleaf clones use `master`

**Problem**: If the user clones their project from Overleaf (which uses
`master`), but `OVERLEAF_BRANCH_LOCAL` defaults to `main`, the push
command tries `git push ... main:master` which fails because the local
branch is called `master`.

**Fix**: After cloning from Overleaf, check `git branch` and set
`OVERLEAF_BRANCH_LOCAL=master` in `.env`.

### 5.5 Paths with spaces break shell commands

**Problem**: Many academic projects live in directories with spaces (e.g.
`Box Sync/LAB/People/...`). Unquoted `${workspaceFolder}` in Run on Save
commands breaks.

**Fix**: Always quote paths: `cd "${workspaceFolder}" && bash ./scripts/...`
The sync script itself handles this by using `cd "$PROJECT_ROOT"`.

---

## 6. Ensuring nothing from LatexCompileSync ends up on Overleaf

- **LatexCompileSync** is a **separate repo** (e.g. `vivekJax/LatexCompileSync`). It is **not** the LaTeX project and **not** the Overleaf project.
- The **user's LaTeX project** is the one that has the remote `origin` pointing at Overleaf and that gets pushed by `sync_to_overleaf.sh`.
- What gets pushed to Overleaf is whatever is **tracked in that LaTeX project's git repo** (and not ignored by `.gitignore`). So:
  - Do **not** add the LatexCompileSync repo as a submodule or copy its `.git` into the LaTeX project.
  - Copy only the **scripts** and **example config** into the LaTeX project; the LaTeX project's `.git` and `.gitignore` control what is pushed to Overleaf.
  - Add `.env` to the LaTeX project's `.gitignore` so the Overleaf token never gets pushed.

With that, **nothing from the LatexCompileSync repo itself** (no separate repo metadata or unrelated files) ends up on Overleaf; only the user's LaTeX files and the copied scripts/config that live inside their project do.

---

## 7. References

- Overleaf Git and token-based auth: [Git integration authentication tokens](https://www.overleaf.com/learn/how-to/Git_integration_authentication_tokens)
- Overleaf project URL → project ID: `https://www.overleaf.com/project/<OVERLEAF_PROJECT_ID>`
- LaTeX Workshop extension: [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop)
- Run on Save extension (optional): [emeraldwalk.RunOnSave](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave)
