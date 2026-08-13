---
name: overleaf-connect
description: Connect a local LaTeX folder to an Overleaf project with LatexCompileSync (compile on save + sync on save). Use when the user pastes an Overleaf project URL, asks to connect/sync Overleaf, or set up LatexCompileSync in Cursor or Claude.
---

# Overleaf connect (Cursor + Claude)

Connect the current LaTeX project folder to Overleaf using LatexCompileSync. Same workflow in **Cursor** and **Claude**.

## When to use

- User pastes `https://www.overleaf.com/project/...`
- User asks to connect, sync, or set up Overleaf / LatexCompileSync for a paper folder

## Requirements

- Project directory: workspace root, or path the user names (`--dir`)
- Overleaf project URL
- Token file (do **not** ask the user to paste the token if this exists):  
  `/Users/vkumar/Tokens_API_Kumar/Overleaf.txt`

## Procedure

1. Confirm the target directory (workspace folder unless the user specifies another).
2. Run setup (**never** put the token on the command line or in chat):

```bash
bash <(curl -sL https://raw.githubusercontent.com/vivekJax/LatexCompileSync/main/scripts/setup.sh) \
  --url "$OVERLEAF_URL" \
  --dir "$PROJECT_DIR" \
  --token-file "/Users/vkumar/Tokens_API_Kumar/Overleaf.txt"
```

If you have a local clone of LatexCompileSync, you may run that repo’s `scripts/setup.sh` the same way instead of curling.

3. After success, tell the user:
   - Detected `MAIN_TEX` and branch mapping (`local → remote`)
   - Install **LaTeX Workshop** if needed
   - **Developer: Reload Window**
   - Saving the main `.tex` builds the PDF and syncs to Overleaf
4. If setup backed up local files, mention `.latexcompilesync_backup/`.

## Rules

- Do **not** read the token file into the chat or echo its contents.
- Do **not** commit `.env`.
- Do **not** manually reimplement sync (git remote with embedded token, etc.) unless setup cannot run — then follow `docs/LLM_GUIDE.md` in the LatexCompileSync repo.
- Deep checklist: https://github.com/vivekJax/LatexCompileSync/blob/main/docs/LLM_GUIDE.md
