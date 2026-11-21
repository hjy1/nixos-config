# Base system. Portable across machines - anything hardware-specific lives in
# hosts/<name>/hardware-configuration.nix instead.
{ config, pkgs, lib, ... }:

{
  # Boot
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  # mkDefault: some firmware (and most VMs) needs this off, which is a
  # per-machine fact.
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  # mkDefault because modules/nvidia.nix pins its driver branch to this
  # choice - see the note there before a host overrides it.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

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
    memoryPercent = lib.mkDefault 25;
  };

  # Microcode and device firmware blobs. The hardware file references this
  # via mkDefault for AMD microcode but never turns it on.
  hardware.enableRedistributableFirmware = true;

  # Networking. The hostname is NOT here: flake.nix derives it from the
  # host's directory name, so hosts/laptop is named "laptop" with no edit.
  networking.networkmanager.enable = true;

  # Locale / time
  time.timeZone = lib.mkDefault "America/Chicago";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
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
    layout = lib.mkDefault "us";
    variant = lib.mkDefault "";
  };

  services.printing.enable = lib.mkDefault true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # The user account lives in modules/user.nix, built from me.nix.
  # Everything else about the user is home-manager: home/, applied by `hms`.

  # vscode, nvidia drivers, steam, bilibili and CUDA are all unfree.
  nixpkgs.config.allowUnfree = true;

  # system.stateVersion is NOT here. It records which NixOS release first
  # installed a *particular machine*, so it is per-host by definition and
  # lives in hosts/<name>/default.nix. A shared value here would hand a
  # machine installed years from now the wrong one.
}
