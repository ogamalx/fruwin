# Codex Local Workspace Task Template (fruWin)

You are working in this local VS Code workspace:
C:\\Users\\omar\\fruwin

Project: **fruWin** – tools to build a “frugal” Linux boot layout from ISOs
by extracting `kernel`, `initrd`, and `squashfs` into `./output/WinuX`
and generating `metadata.txt`.

## General rules

- Work only inside this repo.
- Prefer small, focused changes instead of huge rewrites.
- Keep Bash code beginner-friendly:
  - clear variable names
  - comments explaining non-obvious logic
  - explicit, helpful error messages
- Never introduce placeholders like `/path/to/foo` into runnable scripts.
  Placeholders are only allowed in documentation or comments.
- Before editing a file, inspect its current content.
- At the end, summarise:
  - Which files changed
  - What behaviour changed
  - How to run or test (with exact commands).

## Safety and style

- Use Bash with `set -euo pipefail` for safety.
- Quote variables ("$var") to avoid word-splitting bugs.
- Keep all output under `./output/WinuX`.
- Do not change the meaning of existing options unless the task explicitly asks.

## Current task

Fill in this section each time you create a new Codex task. Example:

```text
Task: Extend create_frugal_from_iso.sh to support a --dry-run flag.

Requirements:
- `--dry-run` may appear before the ISO path.
- In dry-run mode:
  - Discover kernel/initrd/squashfs like normal.
  - Print what would be mounted and copied.
  - Do NOT mount the ISO, copy files, or touch ./output/WinuX.
- Update the usage message to document `--dry-run`.
- Add clear comments for beginners.
- Do not modify unrelated logic.
- Show the diff before applying changes.
- After modifying, summarise exactly what changed and give example commands.
```
