# Base system. Portable across machines - anything hardware-specific lives in
# hosts/<name>/hardware-configuration.nix instead.
{ config, pkgs, ... }:

{
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Flakes need these enabled to build the system at all.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # GC, boot-entry pruning and filesystem upkeep live in modules/maintenance.nix

  # No swap partition on this host (swapDevices = [ ] in the hardware file),
  # and none wanted: hibernation is the only thing that requires disk swap,
  # and it needs a swap area >= RAM (60GiB+ here) to be useful.
  #
  # zram is a compressed block device in RAM used as swap. With 60GiB there is
  # no capacity argument for it - the point is giving the kernel somewhere to
  # put genuinely cold anonymous pages, so reclaim has a cheap option other
  # than dropping page cache or invoking the OOM killer.
  #
  # memoryPercent is the device's *uncompressed capacity*, not RAM consumed -
  # at roughly 3:1 zstd, 25% of 60GiB holds ~15GiB of pages for ~5GiB of real
  # memory. Generous at this RAM size; the module default of 50 is sized for
  # much smaller machines.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Microcode and device firmware blobs. The hardware file references this
  # via mkDefault for AMD microcode but never turns it on.
  hardware.enableRedistributableFirmware = true;

  # Networking
  networking.hostName = "gear";
  networking.networkmanager.enable = true;

  # Locale / time
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."he" = {
    isNormalUser = true;
    description = "Jiayou He";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # vscode, nvidia drivers, steam, bilibili and CUDA are all unfree.
  nixpkgs.config.allowUnfree = true;

  # Do NOT change this, even though the system now tracks unstable.
  # It describes which NixOS release first installed this machine.
  system.stateVersion = "26.05";
}
