# LatexCompileSync

If you work on a LaTeX document in an IDE such as VS Code or Cursor and want to **compile it on save** and **keep an Overleaf project in sync** with your local edits, LatexCompileSync provides the scripts and editor configuration to do both automatically. You edit and save; the PDF rebuilds and the Overleaf project updates without running build or Git commands by hand.

This repository is tooling only — it contains no LaTeX source. You add these scripts and settings to your own LaTeX project (the folder that has your `.tex` file and that you want to sync to Overleaf).

---

## Overview

LatexCompileSync does two things:

1. **Compile on save** — When you save your main `.tex` file (or associated `.sty` or `.bib` files), the document is rebuilt so you can view the updated PDF.
2. **Sync to Overleaf on save** — When you save those files, the project is pushed to your Overleaf project via Git so the online version stays up to date.

Setup is a one-time process: copy the scripts and example config into your project, add your Overleaf credentials to a local `.env` file, and configure your editor. After that, saving triggers compile and sync as configured.

---

## Prerequisites

- **A LaTeX project** — A folder containing your main `.tex` file (e.g. `main.tex` or `paper.tex`).
- **An Overleaf project** — An existing project on [Overleaf](https://www.overleaf.com) that you want to keep in sync with that folder.
- **VS Code or Cursor** — This guide assumes one of these editors; the scripts can also be run from a terminal.
- **LaTeX** — Installed locally (e.g. MacTeX, TeX Live) so the build script can produce a PDF.
- **Git** — Installed so the sync script can push to Overleaf.

---

## Setup

### 1. Add the scripts and config to your project

Clone or download this repo, then copy the following into your LaTeX project folder:

- The **contents** of `scripts/` → into your project’s `scripts/` folder (create it if needed).
- The **contents** of `.vscode/` → into your project’s `.vscode/` folder (create it if needed).

Your project should contain at least:

- Your main `.tex` file (e.g. `main.tex`)
- `scripts/build.sh` and `scripts/sync_to_overleaf.sh`
- `.vscode/` with the editor configuration (recommended)

### 2. Configure Overleaf credentials

In your **LaTeX project root** (the same folder as your main `.tex` file), create a file named `.env` and add:

```
OVERLEAF_PROJECT_ID=your_project_id_here
OVERLEAF_TOKEN=your_token_here
```

**OVERLEAF_PROJECT_ID** — Open your Overleaf project in the browser. The URL has the form `https://www.overleaf.com/project/698bf514322eab4aa8d41e94`. The project ID is the string at the end; use that value for `OVERLEAF_PROJECT_ID`.

**OVERLEAF_TOKEN** — In Overleaf, open your profile (top right) → **Account Settings** → **Git integration**. Generate a token and paste it as `OVERLEAF_TOKEN` in `.env`.

Keep `.env` private: do not commit it to version control. Add `.env` to your project’s `.gitignore`.

If your main file is not `main.tex`, add `MAIN_TEX=yourfile.tex` to `.env`. See [.env.example](.env.example) for other optional variables.

### 3. Connect the project to Overleaf via Git

From your LaTeX project folder in a terminal:

- If the folder is not yet a Git repository:  
  `git init`
- Add the Overleaf project as the remote (replace with your project ID):  
  `git remote add origin https://git.overleaf.com/YOUR_PROJECT_ID`

### 4. Configure the editor

1. **Extensions** — Install **LaTeX Workshop** (for building the PDF) and **Run on Save** (by emeraldwalk) so that saving can trigger the sync task.

2. **Tasks and settings** — In your project’s `.vscode/` folder:
   - Use [.vscode/tasks.json.example](.vscode/tasks.json.example) as the basis for `tasks.json` (or merge its tasks into your existing file).
   - Merge the relevant keys from [.vscode/settings.json.example](.vscode/settings.json.example) into `settings.json`. Set `latex-workshop.latex.mainFile` to your main `.tex` file (e.g. `"main.tex"` or `"paper.tex"`).

3. **Script permissions** — In the project folder, run once:  
   `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`

After this, saving a `.tex`, `.sty`, or `.bib` file can run the **Sync to Overleaf** task; LaTeX Workshop can continue to build the PDF on save as before.

### 5. Verify

1. Open your main `.tex` file in VS Code or Cursor.
2. Make a small edit and save (Ctrl+S / Cmd+S).
3. Check the Terminal or Output panel for a message such as “Synced to Overleaf.”
4. Refresh your Overleaf project in the browser and confirm the change appears.

If you see errors about `OVERLEAF_TOKEN` or `OVERLEAF_PROJECT_ID`, verify the `.env` file and that the project ID and token are correct.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| “OVERLEAF_TOKEN not set” or “OVERLEAF_PROJECT_ID not set” | Create `.env` in the project root with both variables (see step 2 above). |
| “Push failed” | Confirm the project ID in `.env` matches the Overleaf project URL, and that the token is valid (regenerate in Overleaf if needed). |
| PDF does not build | Ensure LaTeX is installed and `latex-workshop.latex.mainFile` in `.vscode/settings.json` points to your main `.tex` file. |
| Sync does not run on save | Ensure the Run on Save extension is installed and that its command in `settings.json` runs the task **“Sync to Overleaf”**. |

---

## Configuration reference

### Files to copy into your LaTeX project

| From this repo | To your project |
|----------------|------------------|
| `scripts/build.sh` | `<project>/scripts/build.sh` |
| `scripts/sync_to_overleaf.sh` | `<project>/scripts/sync_to_overleaf.sh` |
| `.vscode/tasks.json.example` | `<project>/.vscode/tasks.json` (or merge) |
| `.vscode/settings.json.example` | `<project>/.vscode/settings.json` (merge keys) |
| `.env.example` | Use as template; create `<project>/.env` with your values |

### Environment variables (.env)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OVERLEAF_PROJECT_ID` | Yes (for sync) | — | Overleaf project ID from `https://www.overleaf.com/project/<ID>`. |
| `OVERLEAF_TOKEN` | Yes (for sync) | — | Overleaf Git token (Account Settings → Git integration). |
| `MAIN_TEX` | No | `main.tex` | Main `.tex` file to compile. |
| `OUTPUT_PDF` | No | — | If set, copy the built PDF to this path. |
| `TEX_ENGINE` | No | `xelatex` | LaTeX engine: `xelatex`, `pdflatex`, `lualatex`. |
| `OVERLEAF_REMOTE` | No | `origin` | Git remote name for Overleaf. |
| `OVERLEAF_BRANCH_LOCAL` | No | `main` | Local branch to push. |
| `OVERLEAF_BRANCH_REMOTE` | No | `master` | Branch name on Overleaf. |

### Script behavior

- **scripts/build.sh** — Runs from project root (parent of `scripts/`). Loads `.env`, compiles `MAIN_TEX` with `TEX_ENGINE` (two passes). If `OUTPUT_PDF` is set, copies the resulting PDF to that path. Exits with an error if the main file is missing or the build fails.
- **scripts/sync_to_overleaf.sh** — Runs from project root. Loads `.env`. If the folder is not a Git repository, exits successfully without action. Otherwise stages all changes, commits with message “Auto-sync to Overleaf,” and pushes to the Overleaf remote using the configured branch names. The token is used only in the remote URL for the push and is then removed. Exits with an error if credentials are missing or the push fails.

### Requirements

Bash, Git, and a LaTeX distribution (e.g. TeX Live). For the automated workflow: VS Code or Cursor with the LaTeX Workshop and Run on Save extensions.

---

For programmatic integration, automation, and a detailed checklist (including how to ensure no content from this repo is pushed to Overleaf), see **[docs/LLM_GUIDE.md](docs/LLM_GUIDE.md)**.

---

## License

MIT. See [LICENSE](LICENSE).
