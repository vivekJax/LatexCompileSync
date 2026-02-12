# LatexCompileSync — Integration guide for LLMs and developers

This document gives **step-by-step instructions** so an LLM or developer can integrate LatexCompileSync into **any** LaTeX project without tying it to a specific paper or Overleaf project. The tooling is generic and config-driven.

---

## 1. Purpose of this repo

- **LatexCompileSync** provides two behaviors:
  1. **Automated compile**: Build the project’s main `.tex` file when sources change (e.g. on save).
  2. **Automated Overleaf sync**: Commit and push the project to an Overleaf Git remote when sources change (e.g. on save).

- This repo contains **only** scripts, example configs, and docs. **No LaTeX source** and **no Overleaf content** live here. The user’s LaTeX project and Overleaf project are separate; this repo is copied or referenced from the user’s project.

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
│   ├── tasks.json.example    → merge/copy to <project>/.vscode/tasks.json
│   └── settings.json.example → merge/copy to <project>/.vscode/settings.json
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
- **Paths**: All paths are relative to the **project root** after the script’s `cd`.

### 3.2 `scripts/sync_to_overleaf.sh`

- **Invocation**: Run from anywhere; same as `build.sh`, it `cd`s to the project root.
- **Environment / .env** (required for push):
  - `OVERLEAF_PROJECT_ID` — Overleaf project ID (from URL `https://www.overleaf.com/project/<ID>`).
  - `OVERLEAF_TOKEN` — Overleaf Git token (from Account Settings → Git integration).
  - Optional: `OVERLEAF_REMOTE` (default: `origin`), `OVERLEAF_BRANCH_LOCAL` (default: `main`), `OVERLEAF_BRANCH_REMOTE` (default: `master`).
- **Behavior**: If not in a git repo, exits 0. Otherwise loads `.env`, stages all changes, commits with message `"Auto-sync to Overleaf"`, and pushes `OVERLEAF_BRANCH_LOCAL` to `OVERLEAF_BRANCH_REMOTE` on `OVERLEAF_REMOTE`. The remote URL is temporarily set using the token and then cleared. Exits non-zero if token/ID missing or push fails.
- **Important**: The **user’s** LaTeX project must already have `git init` and `git remote add origin https://git.overleaf.com/<OVERLEAF_PROJECT_ID>`. This repo does not create the Overleaf project or remote.

---

## 4. Integrating into a new LaTeX project (checklist for LLMs)

1. **Create `scripts/` in the LaTeX project** and add:
   - `build.sh`
   - `sync_to_overleaf.sh`  
   Make them executable: `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`.

2. **Create or update `.env`** in the project root (do not commit secrets; add `.env` to `.gitignore`):
   - `OVERLEAF_PROJECT_ID=<from Overleaf project URL>`
   - `OVERLEAF_TOKEN=<from Overleaf account settings>`
   - Optional: `MAIN_TEX=...`, `OUTPUT_PDF=...`, `TEX_ENGINE=...` for `build.sh`.

3. **Ensure the project is a git repo** and has the Overleaf remote:
   ```bash
   git init   # if needed
   git remote add origin https://git.overleaf.com/<OVERLEAF_PROJECT_ID>
   ```

4. **Add or merge `.vscode/tasks.json`**:
   - A task **"Build LaTeX"** that runs `./scripts/build.sh` with `cwd: ${workspaceFolder}`.
   - A task **"Sync to Overleaf"** that runs `./scripts/sync_to_overleaf.sh` with `cwd: ${workspaceFolder}`.

5. **Add or merge `.vscode/settings.json`**:
   - LaTeX Workshop: `latex-workshop.latex.autoBuild.run`: `"onSave"`, main file and tools pointing at the project’s main `.tex` and `scripts/build.sh` if desired.
   - Run on Save: when a file matches `\.(tex|sty|bib)$`, run task **"Sync to Overleaf"** so every save to those files triggers a sync.

6. **Remind the user** to install the **Run on Save** extension and to set the main document in Overleaf to the correct `.tex` file.

---

## 5. Ensuring nothing from LatexCompileSync ends up on Overleaf

- **LatexCompileSync** is a **separate repo** (e.g. `vivekJax/LatexCompileSync`). It is **not** the LaTeX project and **not** the Overleaf project.
- The **user’s LaTeX project** is the one that has the remote `origin` pointing at Overleaf and that gets pushed by `sync_to_overleaf.sh`.
- What gets pushed to Overleaf is whatever is **tracked in that LaTeX project’s git repo** (and not ignored by `.gitignore`). So:
  - Do **not** add the LatexCompileSync repo as a submodule or copy its `.git` into the LaTeX project.
  - Copy only the **scripts** and **example config** into the LaTeX project; the LaTeX project’s `.git` and `.gitignore` control what is pushed to Overleaf.
  - Add `.env` to the LaTeX project’s `.gitignore` so the Overleaf token never gets pushed.

With that, **nothing from the LatexCompileSync repo itself** (no separate repo metadata or unrelated files) ends up on Overleaf; only the user’s LaTeX files and the copied scripts/config that live inside their project do.

---

## 6. References

- Overleaf Git and token-based auth: [Git integration authentication tokens](https://www.overleaf.com/learn/how-to/Git_integration_authentication_tokens)
- Overleaf project URL → project ID: `https://www.overleaf.com/project/<OVERLEAF_PROJECT_ID>`
- Run on Save (VS Code): extension that can run a task (e.g. **Sync to Overleaf**) when files matching a pattern are saved.
