# Codex GitHub (Cloud) Task Template (fruWin)

You are working in the GitHub repository `ogamalx/fruwin` on the `main` branch.

Project: **fruWin** – scripts to create a “frugal” Linux boot layout from a
Linux ISO by extracting kernel, initrd, and squashfs into `output/WinuX`
and generating `metadata.txt`.

## General rules

- Only modify files in this repository.
- Prefer small, focused pull requests.
- Keep Bash scripts beginner-friendly with comments and clear errors.
- Keep output layout under `output/WinuX` unchanged unless explicitly requested.
- If behaviour changes, update documentation and comments accordingly.
- For each PR, provide a short summary and optional testing notes.

## Current goal

Fill this in for each Codex GitHub task. Example:

```text
Goal: Improve ISO extraction robustness in create_frugal_from_iso.sh.

Scope:
- Add a root check (exit with clear error if not run as root).
- Use a unique temporary mount directory via mktemp -d.
- Ensure cleanup handles failure cases safely (even if mktemp fails).
- Enhance kernel/initrd/squashfs discovery to handle nested paths
  (e.g. arch/boot/x86_64, casper/live variants).
- Quote metadata values in metadata.txt so paths with spaces are safe.

Constraints:
- Do not change the directory layout under output/WinuX.
- Keep error messages clear for beginners.
- Keep the diff minimal and well-commented.
```
