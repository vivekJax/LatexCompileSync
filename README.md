# LatexCompileSync

**Automated LaTeX compile-on-save and Overleaf sync** for VS Code / Cursor. Use this in any LaTeX project to:

1. **Compile on save** — Build the document whenever you save `.tex`, `.sty`, or `.bib` files (via LaTeX Workshop or a Run-on-Save task).
2. **Sync to Overleaf on save** — Push the project to an Overleaf Git remote whenever you save, so the Overleaf document stays up to date.

This repo is **tooling only**. It contains no LaTeX source; you copy the scripts and config into your own LaTeX project.

---

## Quick start

1. **Clone or copy** this repo (or just the `scripts/` and `.vscode/` example files) into your LaTeX project, or add the repo as a subfolder and run scripts from the project root.

2. **In your LaTeX project root**, ensure you have:
   - `scripts/build.sh`
   - `scripts/sync_to_overleaf.sh`
   - `.env` (copy from `.env.example` and fill in Overleaf credentials)

3. **Configure `.env`** (see [.env.example](.env.example)):
   - `OVERLEAF_PROJECT_ID` — from your Overleaf project URL: `https://www.overleaf.com/project/<ID>`
   - `OVERLEAF_TOKEN` — from [Overleaf → Account Settings → Git integration](https://www.overleaf.com/user/settings) (generate a token)
   - Optional: `MAIN_TEX`, `OUTPUT_PDF`, `TEX_ENGINE` for the build script

4. **Add Overleaf as a Git remote** (if not already):
   ```bash
   git remote add origin https://git.overleaf.com/YOUR_PROJECT_ID
   ```

5. **VS Code / Cursor**: Copy [.vscode/tasks.json.example](.vscode/tasks.json.example) to `.vscode/tasks.json` and [.vscode/settings.json.example](.vscode/settings.json.example) into your `.vscode/settings.json` (merge keys as needed). Install the **Run on Save** extension (e.g. [emeraldwalk.RunOnSave](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave)) so that saving a `.tex` file runs the **Sync to Overleaf** task.

6. **Make scripts executable**: `chmod +x scripts/build.sh scripts/sync_to_overleaf.sh`

---

## What each script does

| Script | Purpose |
|--------|--------|
| `scripts/build.sh` | Compiles `MAIN_TEX` (default `main.tex`) with `TEX_ENGINE` (default `xelatex`). If `OUTPUT_PDF` is set, copies the built PDF to that path. |
| `scripts/sync_to_overleaf.sh` | Runs in the project root; stages all changes, commits with message "Auto-sync to Overleaf", and pushes to the Overleaf remote using `OVERLEAF_PROJECT_ID` and `OVERLEAF_TOKEN` from `.env`. |

Both scripts expect to be run from the **LaTeX project root** (they resolve `scripts/` relative to themselves and then `cd` to the parent directory).

---

## Requirements

- **Bash** (scripts use `bash`)
- **Git** (for Overleaf sync)
- **LaTeX** (e.g. TeX Live; `xelatex`/`pdflatex` in PATH or under `/Library/TeX/texbin/` on macOS)
- **VS Code or Cursor** with:
  - LaTeX Workshop (for compile-on-save)
  - Run on Save extension (to run **Sync to Overleaf** on file save)

---

## License

MIT. See [LICENSE](LICENSE).
