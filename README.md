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

### Option A: One-command setup (recommended)

If you have your **Overleaf project URL** and **Overleaf Git token**, you can set up everything in one step. From your LaTeX project folder (the folder with your `.tex` file), run:

```bash
bash <(curl -sL https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts/setup.sh) \
  --url "https://www.overleaf.com/project/YOUR_PROJECT_ID" \
  --token "YOUR_OVERLEAF_TOKEN"
```

Replace `YOUR_PROJECT_ID` with the ID from your Overleaf project URL (e.g. `686be2799dfc5715eab66dfc`) and `YOUR_OVERLEAF_TOKEN` with your token from Overleaf → Account Settings → Git integration.

The script will:

- Detect your main `.tex` file (the one with `\documentclass`)
- Create `scripts/build.sh` and `scripts/sync_to_overleaf.sh`
- Create `.env` with your credentials and `MAIN_TEX`
- Create or update `.gitignore` and `.vscode/settings.json` / `tasks.json`
- Run `git init`, add the Overleaf remote, and fetch/merge any existing Overleaf content

Then install the **LaTeX Workshop** extension, reload the window, and save a `.tex` file to build and sync.

**To run from a different directory:** add `--dir "/path/to/your/latex/project"` to the command.

---

### Option B: Manual setup

#### 1. Add the scripts and config to your project

Clone or download this repo, then copy the following into your LaTeX project folder:

- The **contents** of `scripts/` → into your project's `scripts/` folder (create it if needed).
- The **contents** of `.vscode/` → into your project's `.vscode/` folder (create it if needed).

Your project should contain at least:

- Your main `.tex` file (e.g. `main.tex`)
- `scripts/build.sh` and `scripts/sync_to_overleaf.sh`
- `.vscode/` with the editor configuration (recommended)

#### 2. Configure Overleaf credentials

In your **LaTeX project root** (the same folder as your main `.tex` file), create a file named `.env` and add:

```
OVERLEAF_PROJECT_ID=your_project_id_here
OVERLEAF_TOKEN=your_token_here
```

**OVERLEAF_PROJECT_ID** — Open your Overleaf project in the browser. The URL has the form `https://www.overleaf.com/project/698bf514322eab4aa8d41e94`. The project ID is the string at the end; use that value for `OVERLEAF_PROJECT_ID`.

**OVERLEAF_TOKEN** — In Overleaf, open your profile (top right) → **Account Settings** → **Git integration**. Generate a token and paste it as `OVERLEAF_TOKEN` in `.env`.

Keep `.env` private: do not commit it to version control. Add `.env` to your project's `.gitignore`.

If your main file is not `main.tex`, add `MAIN_TEX=yourfile.tex` to `.env`. See [.env.example](.env.example) for other optional variables.

#### 3. Connect the project to Overleaf via Git

From your LaTeX project folder in a terminal:

- If the folder is not yet a Git repository:  
  `git init`
- Add the Overleaf project as the remote (replace with your project ID):  
  `git remote add origin https://git.overleaf.com/YOUR_PROJECT_ID`

**Important:** Overleaf's default branch is `master`. If your local clone is also on `master`, set `OVERLEAF_BRANCH_LOCAL=master` in `.env` (the default is `main`).

#### 4. Configure the editor

1. **Extension** — Install **LaTeX Workshop** (for building the PDF). No other extension is required; sync runs as part of the LaTeX Workshop build recipe.

2. **Settings** — Copy [.vscode/settings.json.example](.vscode/settings.json.example) to `.vscode/settings.json` (or merge its keys into your existing file). Set `latex-workshop.latex.mainFile` to your main `.tex` file.

3. **Tasks (optional)** — Copy [.vscode/tasks.json.example](.vscode/tasks.json.example) to `.vscode/tasks.json`. This lets you run **"Sync to Overleaf"** manually from the Command Palette (**Tasks: Run Task**).

4. **Script permissions** — In the project folder, run once:  
   `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`

After this, saving a `.tex`, `.sty`, or `.bib` file will build the PDF and then sync to Overleaf automatically.

#### 5. Verify

1. Open your main `.tex` file in VS Code or Cursor.
2. Make a small edit and save (Ctrl+S / Cmd+S).
3. Check the **LaTeX Workshop** output panel for `[Overleaf sync] ✅ Done — Overleaf updated.`
4. Refresh your Overleaf project in the browser and confirm the change appears.

If you see errors about `OVERLEAF_TOKEN` or `OVERLEAF_PROJECT_ID`, verify the `.env` file and that the project ID and token are correct.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| `[Overleaf sync] ERROR: OVERLEAF_PROJECT_ID or OVERLEAF_TOKEN not set` | Create `.env` in the project root with both variables (see step 2 above). |
| `[Overleaf sync] ❌ Push failed` | 1. Confirm the project ID in `.env` matches the Overleaf project URL. 2. Regenerate the token in Overleaf if it may have expired. 3. Check that Overleaf isn't rejecting the push due to invalid file paths (spaces/special chars in folder names). |
| `failed to get: -50` or `could not read Username` | The macOS Keychain credential helper is intercepting the push. The current sync script disables this automatically — make sure you're using the latest version. |
| PDF does not build | Ensure LaTeX is installed and `latex-workshop.latex.mainFile` in `.vscode/settings.json` points to your main `.tex` file. |
| Sync does not run on save | Verify that `.vscode/settings.json` has the **"Build and Sync"** recipe (see [settings.json.example](.vscode/settings.json.example)). Reload the window (`Cmd+Shift+P` → **Developer: Reload Window**) after changing settings. |
| Overleaf rejects push with "invalid files" | A tracked file has characters Overleaf doesn't allow (e.g. folder names ending in a space). Add those paths to `.gitignore` so they're not staged. |

---

## Configuration reference

### Files to copy into your LaTeX project

| From this repo | To your project |
|----------------|------------------|
| `scripts/setup.sh` | Run once to set up a project (Option A above); or copy `build.sh` / `sync_to_overleaf.sh` manually |
| `scripts/build.sh` | `<project>/scripts/build.sh` |
| `scripts/sync_to_overleaf.sh` | `<project>/scripts/sync_to_overleaf.sh` |
| `.vscode/settings.json.example` | `<project>/.vscode/settings.json` (merge keys) |
| `.vscode/tasks.json.example` | `<project>/.vscode/tasks.json` (optional, for manual sync task) |
| `.env.example` | Use as template; create `<project>/.env` with your values |

### Environment variables (.env)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OVERLEAF_PROJECT_ID` | Yes (for sync) | — | Overleaf project ID from `https://www.overleaf.com/project/<ID>`. |
| `OVERLEAF_TOKEN` | Yes (for sync) | — | Overleaf Git token (Account Settings → Git integration). |
| `MAIN_TEX` | No | `main.tex` | Main `.tex` file to compile. |
| `OUTPUT_PDF` | No | — | If set, copy the built PDF to this path. |
| `TEX_ENGINE` | No | `xelatex` | LaTeX engine: `xelatex`, `pdflatex`, `lualatex`. |
| `OVERLEAF_BRANCH_LOCAL` | No | `main` | Local branch to push. Set to `master` if cloned from Overleaf. |
| `OVERLEAF_BRANCH_REMOTE` | No | `master` | Branch name on Overleaf. |

### Script behavior

- **scripts/setup.sh** — One-command setup for a new LaTeX project. Run from the project folder (or use `--dir`). Requires `--url` (Overleaf project URL) and `--token` (Overleaf Git token). Detects the main `.tex` file, creates `build.sh` and `sync_to_overleaf.sh`, `.env`, `.gitignore`, `.vscode/` config, inits git, adds the Overleaf remote, and fetches/merges existing Overleaf content. Use this so users and LLMs can set up sync with minimal steps.
- **scripts/build.sh** — Runs from project root (parent of `scripts/`). Loads `.env`, compiles `MAIN_TEX` with `TEX_ENGINE` (two passes). If `OUTPUT_PDF` is set, copies the resulting PDF to that path. Exits with an error if the main file is missing or the build fails.
- **scripts/sync_to_overleaf.sh** — Runs from project root. Loads `.env`. If the folder is not a Git repository, exits successfully without action. Otherwise stages all changes (respecting `.gitignore`), commits with message "Auto-sync to Overleaf," and pushes to the Overleaf remote. The token is embedded directly in the push URL (never stored in `.git/config`). Exits with an error if credentials are missing or the push fails.

### Requirements

Bash, Git, and a LaTeX distribution (e.g. TeX Live). For the automated workflow: VS Code or Cursor with the **LaTeX Workshop** extension.

---

For programmatic integration, automation, and a detailed checklist (including how to ensure no content from this repo is pushed to Overleaf), see **[docs/LLM_GUIDE.md](docs/LLM_GUIDE.md)**.

---

## License

MIT. See [LICENSE](LICENSE).
