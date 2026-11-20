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

  # This host has no swap partition (swapDevices = [ ] in the hardware file).
  # zram gives you compressed swap in RAM, which is what keeps a big build -
  # the CUDA toolchain, say - from being OOM-killed outright.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Microcode and device firmware blobs. The hardware file references this
  # via mkDefault for AMD microcode but never turns it on.
  hardware.enableRedistributableFirmware = true;

  # Networking
  # NOTE: left as "nixos" so nothing you didn't ask for changes. The flake
  # output is named `mg1` regardless, hence `--flake ~/nixos-config#mg1`.
  # Set this to "mg1" if you'd rather the two match.
  networking.hostName = "nixos";
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

  programs.firefox.enable = true;

  # vscode, nvidia drivers, steam, bilibili and CUDA are all unfree.
  nixpkgs.config.allowUnfree = true;

  # Do NOT change this, even though the system now tracks unstable.
  # It describes which NixOS release first installed this machine.
  system.stateVersion = "26.05";
}
