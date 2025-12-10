# fruWin

**fruWin** is a small Bash-based toolkit that turns a normal Linux ISO into a **frugal boot layout**.

Instead of doing a full install, fruWin mounts your ISO, finds the kernel, initrd, and squashfs root filesystem,
and copies them into a simple `./output/WinuX` tree that custom bootloaders or Winux-style setups can reuse.

## Features

- Extract Linux boot assets (kernel, initrd, squashfs) from an ISO.
- Write everything into a predictable `output/WinuX` layout:
  - `output/WinuX/boot/vmlinuz`
  - `output/WinuX/boot/initrd.img`
  - `output/WinuX/live/filesystem.squashfs`
- Generate a `metadata.txt` file with the original ISO path, filename, and detected internal paths.
- Support a `--dry-run` mode to preview detections without mounting or copying.

## Quick start

1. Place your Linux ISO somewhere readable.
2. From a Linux shell, clone this repo and `cd` into it.
3. Run the fruWin script:

   ```bash
   # Dry run (no mount, no copies – only detection preview)
   ./create_frugal_from_iso.sh --dry-run /path/to/linux-distro.iso

   # Real extraction (requires root to mount the ISO)
   sudo ./create_frugal_from_iso.sh /path/to/linux-distro.iso
   ```

4. After a successful run, you should see:

   ```text
   output/WinuX/boot/vmlinuz
   output/WinuX/boot/initrd.img
   output/WinuX/live/filesystem.squashfs
   output/WinuX/metadata.txt
   ```

## Layout

```text
fruWin/
  create_frugal_from_iso.sh
  output/
    WinuX/
      boot/
      live/
  docs/
    CODEX_TASK_TEMPLATE-local.md
    CODEX_TASK_TEMPLATE-cloud.md
    DESIGN.md
```

## Using Codex or other agents

This repo is designed to work well with coding agents like Codex:

- `docs/CODEX_TASK_TEMPLATE-local.md` describes how to talk to Codex when it is running
  against your local workspace (VS Code Codex extension).
- `docs/CODEX_TASK_TEMPLATE-cloud.md` describes how to talk to Codex when it is working
  via GitHub to create branches and pull requests.

The idea is simple: you paste the right template, fill in the **CURRENT TASK** section,
and let the agent do focused work without changing the overall project shape.

## Contributing

- Keep Bash scripts beginner-friendly: clear variable names and comments.
- Prefer small, focused changes rather than huge refactors.
- Try to keep all output under `output/WinuX`.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
