# LatexCompileSync

Automatically **compile your LaTeX document** and **update your Overleaf project** whenever you save your files. No need to run build or push commands by hand.

This repo is **tooling only** — no LaTeX files. You add these scripts and settings to your own LaTeX project (the one with your `.tex` file and Overleaf).

---

# Part 1: Human-readable guide (if you’re not a programmer)

## What this does

1. **Compile on save** — When you save your main `.tex` file (or style/bib files), your PDF is rebuilt so you can see the latest result.
2. **Sync to Overleaf on save** — When you save those same files, the project is pushed to your Overleaf project so the online version stays in sync.

You use an editor (VS Code or Cursor) and a couple of small “scripts” (prewritten commands). You don’t have to type Git or LaTeX commands yourself after setup.

---

## What you’ll need

- **A LaTeX project** — A folder that has your main `.tex` file (e.g. `main.tex` or `paper.tex`).
- **An Overleaf project** — You already have a project on [Overleaf](https://www.overleaf.com) that you want to keep in sync with that folder.
- **VS Code or Cursor** — A code editor. If you use something else, you can still run the scripts from a terminal; this guide focuses on the editor.
- **LaTeX installed** — So your computer can build PDFs (e.g. MacTeX/TeX Live).
- **Git installed** — So the sync script can push to Overleaf.

---

## Step 1: Get the scripts into your project

- **Option A:** Clone this repo, then copy the **contents** of `scripts/` and the **contents** of `.vscode/` into your LaTeX project’s `scripts/` and `.vscode/` folders (create those folders if needed).  
- **Option B:** Download this repo as a ZIP, unzip it, then copy the `scripts` folder and the `.vscode` folder into your LaTeX project folder.

Your LaTeX project folder should look something like:

- Your main `.tex` file (e.g. `main.tex`)
- A `scripts` folder with `build.sh` and `sync_to_overleaf.sh` inside it
- A `.vscode` folder (optional but recommended) with the editor settings

---

## Step 2: Create a `.env` file (for Overleaf sync)

In your **LaTeX project folder** (same place as your main `.tex` file), create a new file named exactly `.env`. No name before the dot — just `.env`.

Put these two lines in it (replace the placeholders with your real values):

```
OVERLEAF_PROJECT_ID=your_project_id_here
OVERLEAF_TOKEN=your_token_here
```

**Where to get these:**

- **OVERLEAF_PROJECT_ID**  
  Open your Overleaf project in the browser. Look at the URL. It will look like:  
  `https://www.overleaf.com/project/698bf514322eab4aa8d41e94`  
  The **project ID** is the long string at the end (e.g. `698bf514322eab4aa8d41e94`). Copy that into `.env` as `OVERLEAF_PROJECT_ID=...`.

- **OVERLEAF_TOKEN**  
  1. In Overleaf, click your profile (top right) and open **Account Settings**.  
  2. Find **Git integration** (or “Git” in the menu).  
  3. Click **Generate token** (or similar).  
  4. Copy the token and put it in `.env` as `OVERLEAF_TOKEN=...`.

**Important:** Keep `.env` private. Don’t share it or commit it to a public place. Add `.env` to your project’s `.gitignore` if you use Git.

**Optional:** If your main file is not `main.tex`, add a line like `MAIN_TEX=yourfile.tex`. You can copy the rest from the `.env.example` file in this repo.

---

## Step 3: Connect your folder to Overleaf with Git

Your LaTeX folder needs to be a Git repo and know the address of your Overleaf project.

- If the folder is **not** yet a Git repo, open Terminal (or Command Prompt), go to your LaTeX project folder, and run:  
  `git init`
- Then add Overleaf as the remote (use your real project ID):  
  `git remote add origin https://git.overleaf.com/YOUR_PROJECT_ID`

If someone already set this up for you, you can skip this step.

---

## Step 4: Set up the editor (VS Code or Cursor)

1. **Install extensions**
   - **LaTeX Workshop** — so the editor can build your PDF.
   - **Run on Save** (by emeraldwalk) — so saving a file can run “Sync to Overleaf”.

2. **Use the example settings**
   - In this repo there are example files: `.vscode/tasks.json.example` and `.vscode/settings.json.example`.
   - In your LaTeX project, in the `.vscode` folder:
     - Copy `tasks.json.example` to `tasks.json` (or add its contents into your existing `tasks.json`).
     - Merge the contents of `settings.json.example` into your `settings.json` (or create one).  
   - In `settings.json`, set `latex-workshop.latex.mainFile` to your main `.tex` file name (e.g. `"main.tex"` or `"paper.tex"`).

3. **Make the scripts runnable (once)**  
   In Terminal, go to your LaTeX project folder and run:  
   `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`

After this, when you **save** a `.tex`, `.sty`, or `.bib` file, the editor can run “Sync to Overleaf” so your Overleaf project updates. LaTeX Workshop can still build the PDF on save as before.

---

## Step 5: Check that it works

1. Open your main `.tex` file in VS Code or Cursor.
2. Make a small change (e.g. add a space or a word) and save (Ctrl+S / Cmd+S).
3. Look at the bottom or the “Terminal” / “Output” panel; you should see a message like “Synced to Overleaf” if the sync ran.
4. In your browser, open your Overleaf project and refresh; you should see the change.

If you see an error about “OVERLEAF_TOKEN” or “OVERLEAF_PROJECT_ID”, double-check your `.env` file and that the project ID and token are correct.

---

## Troubleshooting (plain language)

- **“OVERLEAF_TOKEN not set”** — Create the `.env` file in your LaTeX project folder and add the two lines (project ID and token) as in Step 2.
- **“Push failed”** — Check that the project ID in `.env` matches the one in your Overleaf URL, and that the token is valid (generate a new one in Overleaf if needed).
- **PDF doesn’t build** — Make sure LaTeX is installed and that `latex-workshop.latex.mainFile` in `.vscode/settings.json` points to your main `.tex` file.
- **Sync doesn’t run on save** — Make sure the “Run on Save” extension is installed and that in `.vscode/settings.json` the Run on Save command is set to run the task named **“Sync to Overleaf”**.

---

# Part 2: Quick reference (machine- and LLM-friendly)

## Repo contents (what to copy into a LaTeX project)

| Copy from this repo | Into LaTeX project |
|--------------------|---------------------|
| `scripts/build.sh` | `<project>/scripts/build.sh` |
| `scripts/sync_to_overleaf.sh` | `<project>/scripts/sync_to_overleaf.sh` |
| `.vscode/tasks.json.example` | `<project>/.vscode/tasks.json` (or merge) |
| `.vscode/settings.json.example` | `<project>/.vscode/settings.json` (merge keys) |
| `.env.example` | Use as template; create `<project>/.env` with secrets |

## Environment variables (.env in project root)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OVERLEAF_PROJECT_ID` | Yes (for sync) | — | Overleaf project ID from URL `https://www.overleaf.com/project/<ID>`. |
| `OVERLEAF_TOKEN` | Yes (for sync) | — | Overleaf Git token (Account Settings → Git integration). |
| `MAIN_TEX` | No | `main.tex` | Main .tex file to compile. |
| `OUTPUT_PDF` | No | — | If set, copy built PDF to this path. |
| `TEX_ENGINE` | No | `xelatex` | LaTeX engine: `xelatex`, `pdflatex`, `lualatex`. |
| `OVERLEAF_REMOTE` | No | `origin` | Git remote name for Overleaf. |
| `OVERLEAF_BRANCH_LOCAL` | No | `main` | Local branch to push. |
| `OVERLEAF_BRANCH_REMOTE` | No | `master` | Overleaf branch name. |

## Script behavior (contracts)

- **scripts/build.sh** — `cd`s to project root (parent of `scripts/`). Loads `.env`. Compiles `MAIN_TEX` with `TEX_ENGINE` (twice). If `OUTPUT_PDF` is set, copies `<MAIN_TEX base>.pdf` to `OUTPUT_PDF`. Exit non-zero on missing file or build failure.
- **scripts/sync_to_overleaf.sh** — `cd`s to project root. Loads `.env`. If not a git repo, exit 0. Else: `git add -A`; if nothing staged, exit 0; else `git commit -m "Auto-sync to Overleaf"` and `git push OVERLEAF_REMOTE OVERLEAF_BRANCH_LOCAL:OVERLEAF_BRANCH_REMOTE`. Uses token in remote URL temporarily. Exit non-zero if token/ID missing or push fails.

## Requirements

- Bash, Git, LaTeX (e.g. TeX Live). VS Code or Cursor with LaTeX Workshop and Run on Save extension.

## Full LLM integration guide

For detailed, step-by-step integration instructions (file layout, script contracts, checklist, ensuring nothing from this repo is pushed to Overleaf), see **[docs/LLM_GUIDE.md](docs/LLM_GUIDE.md)**.

---

## License

MIT. See [LICENSE](LICENSE).
