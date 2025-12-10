#!/bin/bash
# create_frugal_from_iso.sh
#
# Create a WinuX-style "frugal" layout by extracting the kernel, initrd, and
# squashfs from a Linux ISO into ./output/WinuX.
#
# Normal run (does real work, needs root):
#   sudo ./create_frugal_from_iso.sh /path/to/linux-distro.iso
#
# Dry run (no mount, no copies, just detection preview):
#   ./create_frugal_from_iso.sh --dry-run /path/to/linux-distro.iso
#
# Dry run inspects the ISO using bsdtar or isoinfo so you can see what WOULD be
# mounted and copied without touching the filesystem.
#
# This script is designed to be:
# - Beginner-friendly (lots of comments, clear errors)
# - Safe (set -euo pipefail, quoted variables)
# - Agent-friendly (clear structure for tools like Codex).

set -euo pipefail

print_usage() {
    echo "Usage: $0 [--dry-run] /path/to/linux-distro.iso"
    echo
    echo "Examples:"
    echo "  Dry run (preview only, no mount, no copies):"
    echo "    $0 --dry-run Downloads/ubuntu.iso"
    echo
    echo "  Real extraction (requires root to mount the ISO):"
    echo "    sudo $0 Downloads/ubuntu.iso"
}

# Optional --dry-run flag comes first.
DRY_RUN=0
if [[ $# -ge 1 && "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi

# Now we expect at least one argument: the ISO path.
if [[ $# -lt 1 ]]; then
    echo "Error: missing ISO path." >&2
    print_usage
    exit 1
fi

ISO_PATH="$1"

# Fast feedback if the ISO path is wrong.
if [[ ! -f "$ISO_PATH" ]]; then
    echo "Error: ISO file '$ISO_PATH' not found." >&2
    exit 1
fi

# Common directories where distros keep their boot files and root filesystem.
search_dirs=("casper" "live" "boot" "arch/boot")

############################################
# DRY RUN MODE – NO MOUNT, NO COPIES
############################################
if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "=== Dry run mode ==="
    echo "ISO: $ISO_PATH"
    echo "This will NOT mount the ISO or copy any files."
    echo

    # Helper to list ISO contents without mounting.
    list_iso_contents() {
        # Prefer bsdtar if available.
        if command -v bsdtar >/dev/null 2>&1; then
            bsdtar -tf "$ISO_PATH"
            return 0
        fi
        # Fallback to isoinfo if available.
        if command -v isoinfo >/dev/null 2>&1; then
            isoinfo -J -f -i "$ISO_PATH" 2>/dev/null
            return 0
        fi
        return 1
    }

    # We temporarily relax pipefail while capturing the full listing.
    set +o pipefail
    if ! iso_listing="$(list_iso_contents)"; then
        set -o pipefail
        echo "Error: dry run requires either 'bsdtar' or 'isoinfo' to be installed." >&2
        echo "Install one of them, or run the script without --dry-run to use mount-based detection." >&2
        exit 1
    fi
    set -o pipefail

    kernel_rel=""
    initrd_rel=""
    squashfs_rel=""

    # Walk the listing multiple times, once per preferred directory.
    for dir in "${search_dirs[@]}"; do
        while IFS= read -r path; do
            # Normalise optional leading slash from isoinfo output.
            case "$path" in
                /*) rel="${path#/}" ;;
                *)  rel="$path" ;;
            esac

            # Only consider paths under the current search directory.
            case "$rel" in
                "$dir"/vmlinuz*|"$dir"/*/vmlinuz*)
                    if [[ -z "$kernel_rel" ]]; then
                        kernel_rel="$rel"
                    fi
                    ;;
                "$dir"/initrd*|"$dir"/*/initrd*|"$dir"/initramfs*|"$dir"/*/initramfs*)
                    if [[ -z "$initrd_rel" ]]; then
                        initrd_rel="$rel"
                    fi
                    ;;
                "$dir"/*.squashfs|"$dir"/*/*.squashfs)
                    if [[ -z "$squashfs_rel" ]]; then
                        squashfs_rel="$rel"
                    fi
                    ;;
            esac

            if [[ -n "$kernel_rel" && -n "$initrd_rel" && -n "$squashfs_rel" ]]; then
                break
            fi
        done <<< "$iso_listing"

        if [[ -n "$kernel_rel" && -n "$initrd_rel" && -n "$squashfs_rel" ]]; then
            break
        fi
    done

    if [[ -z "$kernel_rel" ]]; then
        echo "Error (dry run): could not locate a kernel (vmlinuz*) inside the ISO listing." >&2
        exit 1
    fi
    if [[ -z "$initrd_rel" ]]; then
        echo "Error (dry run): could not locate an initrd (initrd* or initramfs*) inside the ISO listing." >&2
        exit 1
    fi
    if [[ -z "$squashfs_rel" ]]; then
        echo "Error (dry run): could not locate a squashfs (*.squashfs) inside the ISO listing." >&2
        exit 1
    fi

    echo "Detected boot assets (preview only):"
    echo "  Kernel inside ISO:   $kernel_rel"
    echo "  Initrd inside ISO:   $initrd_rel"
    echo "  Squashfs inside ISO: $squashfs_rel"
    echo
    echo "If you ran a REAL extraction, the script would:"
    echo "  - Mount the ISO read-only"
    echo "  - Copy:"
    echo "      $kernel_rel   -> ./output/WinuX/boot/vmlinuz"
    echo "      $initrd_rel   -> ./output/WinuX/boot/initrd.img"
    echo "      $squashfs_rel -> ./output/WinuX/live/filesystem.squashfs"
    echo "  - Write ./output/WinuX/metadata.txt with these paths and a timestamp"
    echo
    echo "Dry run complete. No mount was performed and no files were written."
    exit 0
fi

############################################
# REAL EXTRACTION – MOUNT AND COPY FILES
############################################

# Require root so mounting succeeds.
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Error: this script must be run as root to mount ISOs." >&2
    exit 1
fi

# Prepare a unique temporary mount directory that will be cleaned up automatically.
TMP_MOUNT="$(mktemp -d -t fruwin_iso_mount.XXXXXX)"

cleanup() {
    # Unmount the ISO if it is still mounted.
    if [[ -n "${TMP_MOUNT-}" && -d "$TMP_MOUNT" ]] && mountpoint -q "$TMP_MOUNT"; then
        umount "$TMP_MOUNT" 2>/dev/null || true
    fi
    # Remove the temporary directory to keep the workspace tidy.
    if [[ -n "${TMP_MOUNT-}" && -d "$TMP_MOUNT" ]]; then
        rm -rf "$TMP_MOUNT" 2>/dev/null || true
    fi
}

trap cleanup EXIT

echo "Mounting ISO read-only at $TMP_MOUNT..."
if ! mount -o loop,ro "$ISO_PATH" "$TMP_MOUNT"; then
    echo "Error: failed to mount ISO at '$ISO_PATH'." >&2
    exit 1
fi

echo "Searching for kernel, initrd, and squashfs files..."

# Helper to find the first file match up to two levels deep.
find_first_match() {
    local base_dir="$1"
    shift
    if [[ -d "$base_dir" ]]; then
        find "$base_dir" -maxdepth 2 -type f "$@" -print -quit
    fi
}

kernel_path=""
initrd_path=""
squashfs_path=""

for dir in "${search_dirs[@]}"; do
    dir_path="$TMP_MOUNT/$dir"
    if [[ -d "$dir_path" ]]; then
        if [[ -z "$kernel_path" ]]; then
            kernel_path="$(find_first_match "$dir_path" -name 'vmlinuz*' || true)"
        fi
        if [[ -z "$initrd_path" ]]; then
            initrd_path="$(find_first_match "$dir_path" \( -name 'initrd*' -o -name 'initramfs*' \) || true)"
        fi
        if [[ -z "$squashfs_path" ]]; then
            squashfs_path="$(find_first_match "$dir_path" -name '*.squashfs' || true)"
        fi
    fi

    if [[ -n "$kernel_path" && -n "$initrd_path" && -n "$squashfs_path" ]]; then
        break
    fi
done

if [[ -z "$kernel_path" ]]; then
    echo "Error: could not find a kernel (vmlinuz*) inside the mounted ISO." >&2
    exit 1
fi
if [[ -z "$initrd_path" ]]; then
    echo "Error: could not find an initrd (initrd* or initramfs*) inside the mounted ISO." >&2
    exit 1
fi
if [[ -z "$squashfs_path" ]]; then
    echo "Error: could not find a squashfs (*.squashfs) inside the mounted ISO." >&2
    exit 1
fi

kernel_rel="${kernel_path#"$TMP_MOUNT"/}"
initrd_rel="${initrd_path#"$TMP_MOUNT"/}"
squashfs_rel="${squashfs_path#"$TMP_MOUNT"/}"

echo "Detected kernel:   $kernel_rel"
echo "Detected initrd:   $initrd_rel"
echo "Detected squashfs: $squashfs_rel"

mkdir -p ./output/WinuX/boot ./output/WinuX/live

cp -f "$kernel_path"   ./output/WinuX/boot/vmlinuz
cp -f "$initrd_path"   ./output/WinuX/boot/initrd.img
cp -f "$squashfs_path" ./output/WinuX/live/filesystem.squashfs

echo "Writing metadata to ./output/WinuX/metadata.txt"
cat > ./output/WinuX/metadata.txt <<METADATA
Original ISO path: "$ISO_PATH"
ISO filename: "$(basename "$ISO_PATH")"
Kernel path inside ISO: "$kernel_rel"
Initrd path inside ISO: "$initrd_rel"
Squashfs path inside ISO: "$squashfs_rel"
Timestamp: "$(date)"
METADATA

echo "Frugal extraction complete. Files have been placed in ./output/WinuX."
