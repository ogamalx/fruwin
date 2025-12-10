# fruWin Design Notes

fruWin is meant to stay very small and focused:

- **Input**: a single Linux ISO file.
- **Output**: a standardised `output/WinuX` tree with:
  - `boot/vmlinuz`
  - `boot/initrd.img`
  - `live/filesystem.squashfs`
  - `metadata.txt` describing what was detected.

## Core script

The main script is `create_frugal_from_iso.sh`. Its responsibilities:

- Validate input (ISO exists, root when needed).
- Mount ISO read-only in a temporary directory (real run).
- Detect kernel/initrd/squashfs in distro-specific paths.
- Copy assets into the WinuX layout.
- Write `metadata.txt` for traceability.
- Provide a `--dry-run` mode to preview detection without mounting or copying.

## Future ideas

- Detect distro flavor (Debian/Ubuntu/Arch/antiX/etc.) and record it.
- Generate GRUB menu entries based on `metadata.txt`.
- Support multiple ISOs in one run for multi-boot setups.
- Optional GUI or TUI wrapper later.
