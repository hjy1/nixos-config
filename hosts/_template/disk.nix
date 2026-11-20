# Declarative disk layout for a NEW machine, via disko.
#
#   !!  DESTRUCTIVE  !!
# `disko --mode destroy,format,mount` wipes the named device with no prompt.
# This file is only ever run from an installer ISO against a blank disk.
# NEVER run it against a disk holding a system you care about.
#
# Copy to hosts/<name>/disk.nix, set `device` to the real disk, then:
#   lsblk                                    # find the device name
#   sudo disko --mode destroy,format,mount /mnt/cfg/hosts/<name>/disk.nix
#
# disko generates the fileSystems.* entries itself, so the generated
# hardware-configuration.nix for this host will be much smaller - no
# hand-copied UUIDs.
{
  disko.devices.disk.main = {
    # CHANGE THIS. /dev/nvme0n1 for NVMe, /dev/sda for SATA.
    # Prefer a stable path like /dev/disk/by-id/... on multi-disk machines.
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" "nixos" "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
