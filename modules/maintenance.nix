# Housekeeping: garbage collection, boot-entry pruning, filesystem upkeep.
{ config, pkgs, lib, ... }:

{
  # Your ESP is 1G. Each generation keeps a kernel + initrd in /boot, so an
  # unbounded list will eventually fill it - and a full ESP makes rebuilds
  # fail in a confusing way. Cap the bootloader menu.
  boot.loader.systemd-boot.configurationLimit = 10;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings = {
    auto-optimise-store = true;
    # Silences the "Git tree is dirty" noise while you're editing the flake.
    warn-dirty = false;
    # Lets you (not just root) add substituters and use nix-copy-closure.
    trusted-users = [ "root" "@wheel" ];
  };

  # NVMe: periodic TRIM keeps write performance from degrading.
  services.fstrim.enable = true;

  # btrfs: scrub verifies checksums across the filesystem and catches silent
  # corruption early. Assumes a btrfs root, which this host has.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
