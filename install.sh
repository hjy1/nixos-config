#!/usr/bin/env bash
# Installer for this flake, run from a NixOS ISO. Two phases, deliberately
# separate because they are different kinds of operation:
#
#   prepare <host> <disk>   DESTRUCTIVE, machine-specific, happens once ever.
#                           Partitions the disk and probes the hardware.
#
#   apply <host>            Declarative and repeatable. Builds and installs
#                           the software configuration. Safe to re-run.
#
#   mount <host>            Non-destructive remount of an already-prepared
#                           disk (use after rebooting the ISO mid-install).
#
# Typical run:
#   lsblk
#   sudo ./install.sh prepare laptop /dev/nvme0n1
#   # review hosts/laptop/, edit default.nix to pick modules
#   sudo ./install.sh apply laptop

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="he"

die()  { printf '\n\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }

usage() {
  # Print the header comment block, stopping at the first line of real code.
  awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
  exit "${1:-1}"
}

need_root() { [[ $EUID -eq 0 ]] || die "must run as root (use sudo)"; }
valid_host() {
  [[ "$1" =~ ^[a-z0-9-]+$ ]] || die "hostname must be lowercase letters, digits, dashes"
  [[ ! "$1" =~ ^_ ]]         || die "names starting with _ are reserved for templates"
}

export NIX_CONFIG="experimental-features = nix-command flakes"

# ---------------------------------------------------------------- prepare ---
cmd_prepare() {
  [[ $# -eq 2 ]] || die "usage: sudo $0 prepare <host> <disk>
  e.g. sudo $0 prepare laptop /dev/nvme0n1
  run 'lsblk' to list disks"

  local host="$1" disk="$2"
  need_root
  valid_host "$host"
  [[ -b "$disk" ]] || die "$disk is not a block device. Run 'lsblk'."
  [[ ! -d "$REPO/hosts/$host" ]] \
    || die "hosts/$host already exists.
  To start that host over:  rm -rf $REPO/hosts/$host"

  echo
  lsblk "$disk" || true
  cat <<WARN

  This PERMANENTLY ERASES $disk and prepares host '$host'.
  Everything on that disk will be gone. There is no undo.

WARN
  read -rp "  Type the disk path again to confirm: " confirm
  [[ "$confirm" == "$disk" ]] || die "confirmation did not match - nothing was changed"

  step "Creating hosts/$host from template"
  cp -r "$REPO/hosts/_template" "$REPO/hosts/$host"
  sed -i "s|device = \"/dev/nvme0n1\";|device = \"$disk\";|" "$REPO/hosts/$host/disk.nix"
  grep -q "device = \"$disk\";" "$REPO/hosts/$host/disk.nix" \
    || die "failed to write device into hosts/$host/disk.nix"

  step "Partitioning and mounting $disk"
  nix run "$REPO#disko" -- --mode destroy,format,mount "$REPO/hosts/$host/disk.nix"
  mountpoint -q /mnt || die "disko finished but /mnt is not mounted"

  # --no-filesystems: disko already declares every fileSystems.* entry, and
  # duplicate definitions would conflict.
  step "Probing hardware"
  nixos-generate-config --root /mnt --no-filesystems
  cp /mnt/etc/nixos/hardware-configuration.nix "$REPO/hosts/$host/"

  # New files are invisible to the flake until git knows about them.
  step "Staging new files for git"
  git -C "$REPO" add -A

  findmnt -R /mnt -o TARGET,SOURCE,FSTYPE || true
  cat <<DONE

  Prepared. Nothing has been installed yet.

  Review before applying:
    $REPO/hosts/$host/default.nix              which modules this host gets
    $REPO/hosts/$host/hardware-configuration.nix

  modules/nvidia.nix is commented out by default (it pulls in a multi-GB
  CUDA closure). Uncomment it only if this machine has an NVIDIA GPU.

  Then:
    sudo $0 apply $host

DONE
}

# ------------------------------------------------------------------ mount ---
cmd_mount() {
  [[ $# -eq 1 ]] || die "usage: sudo $0 mount <host>"
  local host="$1"
  need_root
  [[ -f "$REPO/hosts/$host/disk.nix" ]] || die "no hosts/$host/disk.nix - run prepare first"

  step "Mounting host '$host' (non-destructive)"
  nix run "$REPO#disko" -- --mode mount "$REPO/hosts/$host/disk.nix"
  mountpoint -q /mnt || die "/mnt still not mounted"
  findmnt -R /mnt -o TARGET,SOURCE,FSTYPE
}

# ------------------------------------------------------------------ apply ---
cmd_apply() {
  [[ $# -eq 1 ]] || die "usage: sudo $0 apply <host>"
  local host="$1"
  need_root
  valid_host "$host"

  [[ -d "$REPO/hosts/$host" ]] \
    || die "hosts/$host does not exist. Run:  sudo $0 prepare $host <disk>"
  [[ -f "$REPO/hosts/$host/hardware-configuration.nix" ]] \
    || die "hosts/$host has no hardware-configuration.nix. Run prepare first."
  mountpoint -q /mnt \
    || die "/mnt is not mounted. If the disk is already prepared:  sudo $0 mount $host"

  # Re-stage in case the host files were edited since prepare.
  git -C "$REPO" add -A

  step "Building and installing host '$host'"
  note "this is the slow part"
  nixos-install --flake "$REPO#$host" --no-root-password

  # A declared user with no password has login DISABLED, not blank. Both of
  # these must happen before the first reboot or you cannot reach a desktop.
  step "Set the root password"
  nixos-enter --root /mnt -c 'passwd root'
  step "Set the password for $USERNAME"
  nixos-enter --root /mnt -c "passwd $USERNAME"

  cat <<DONE

  Host '$host' installed. Reboot and remove the USB.

  Then on the new machine:
    git clone https://github.com/joure5501/nixos-config ~/nixos-config
    cd ~/nixos-config && git commit -am "add $host" && git push
    mkdir -p ~/.config/niri
    ln -sf ~/nixos-config/dotfiles/niri/config.kdl ~/.config/niri/config.kdl

  From here on you never use this script again - it is
    sudo nixos-rebuild switch --flake ~/nixos-config#$host

DONE
}

case "${1:-}" in
  prepare) shift; cmd_prepare "$@" ;;
  mount)   shift; cmd_mount   "$@" ;;
  apply)   shift; cmd_apply   "$@" ;;
  -h|--help|help) usage 0 ;;
  "")      usage 1 ;;
  *)       die "unknown command '${1}'. Try: prepare | apply | mount" ;;
esac
