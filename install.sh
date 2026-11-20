#!/usr/bin/env bash
# Two-step NixOS install.
#
#   1.  nix-shell -p git --run 'git clone https://github.com/joure5501/nixos-config /tmp/cfg'
#   2.  sudo /tmp/cfg/install.sh <hostname> <disk>
#
# e.g.  sudo /tmp/cfg/install.sh laptop /dev/nvme0n1
#
# Partitions the disk (DESTRUCTIVE), installs the system, and sets both
# passwords. Run from the NixOS installer ISO.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="he"

die() { printf '\nerror: %s\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

[[ $# -eq 2 ]] || die "usage: sudo $0 <hostname> <disk>
  e.g. sudo $0 laptop /dev/nvme0n1
  run 'lsblk' to find the disk"

HOST="$1"
DISK="$2"

[[ $EUID -eq 0 ]] || die "must run as root (use sudo)"
[[ -b "$DISK" ]]  || die "$DISK is not a block device. Run 'lsblk'."
[[ "$HOST" =~ ^[a-z0-9-]+$ ]] || die "hostname must be lowercase letters, digits, dashes"
[[ ! -d "$REPO/hosts/$HOST" ]] || die "hosts/$HOST already exists - pick another name"

export NIX_CONFIG="experimental-features = nix-command flakes"

# --- confirm, because the next phase is unrecoverable ----------------------
echo
lsblk "$DISK" || true
cat <<WARN

  This will PERMANENTLY ERASE $DISK and install NixOS host '$HOST'.
  Everything currently on that disk will be gone. There is no undo.

WARN
read -rp "Type the disk path again to confirm: " confirm
[[ "$confirm" == "$DISK" ]] || die "confirmation did not match - nothing was changed"

# --- host directory -------------------------------------------------------
step "Creating hosts/$HOST"
cp -r "$REPO/hosts/_template" "$REPO/hosts/$HOST"
# Point the disk spec at the real device.
sed -i "s|device = \"/dev/nvme0n1\";|device = \"$DISK\";|" "$REPO/hosts/$HOST/disk.nix"
grep -q "device = \"$DISK\";" "$REPO/hosts/$HOST/disk.nix" \
  || die "failed to set device in hosts/$HOST/disk.nix"

# --- partition + mount ----------------------------------------------------
step "Partitioning $DISK with disko"
nix run "$REPO#disko" -- --mode destroy,format,mount "$REPO/hosts/$HOST/disk.nix"
mountpoint -q /mnt || die "disko finished but /mnt is not mounted"

# --- hardware scan --------------------------------------------------------
# --no-filesystems: disko already declares every fileSystems.* entry, and
# duplicates would conflict.
step "Scanning hardware"
nixos-generate-config --root /mnt --no-filesystems
cp /mnt/etc/nixos/hardware-configuration.nix "$REPO/hosts/$HOST/"

# --- stage, or the flake cannot see the new files -------------------------
step "Staging new files for git"
git -C "$REPO" add -A

# --- install --------------------------------------------------------------
step "Installing (this takes a while)"
nixos-install --flake "$REPO#$HOST" --no-root-password

# --- passwords ------------------------------------------------------------
# A declared user with no password has login DISABLED, not blank - so this
# must happen before the first reboot or you cannot reach your desktop.
step "Set the root password"
nixos-enter --root /mnt -c 'passwd root'
step "Set the password for $USERNAME"
nixos-enter --root /mnt -c "passwd $USERNAME"

cat <<DONE

  Done. Host '$HOST' installed.

  Next:
    reboot                       (remove the USB)

  Then, on the new machine:
    cd ~/nixos-config && git commit -am "add $HOST" && git push
    mkdir -p ~/.config/niri
    ln -sf ~/nixos-config/dotfiles/niri/config.kdl ~/.config/niri/config.kdl

  Note: this repo lives at $REPO, which is inside the installer.
  Clone it again on the new system to keep working on it.

DONE
