# Housekeeping: garbage collection, boot-entry pruning, filesystem upkeep.
{ config, pkgs, lib, ... }:

{
  # Your ESP is 1G. Each generation keeps a kernel + initrd in /boot, so an
  # unbounded list will eventually fill it - and a full ESP makes rebuilds
  # fail in a confusing way. Cap the bootloader menu.
  #
  # mkDefault: ESP size is a per-host fact, so a machine with a 512M ESP
  # should lower this from its own host file.
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  nix.gc = {
    automatic = true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 30d";
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
  # corruption early.
  #
  # Enabled from the root filesystem's own type rather than assumed: this
  # module is unconditional for every host, and a scrub timer on an ext4 or
  # ZFS root is a unit that fails every month for no reason.
  services.btrfs.autoScrub = {
    enable = lib.mkDefault (config.fileSystems."/".fsType or "" == "btrfs");
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
