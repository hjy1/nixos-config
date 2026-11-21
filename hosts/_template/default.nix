# Template host. Copy this directory to hosts/<name>/ - the directory name
# becomes the hostname, and flake.nix discovers it with no edit.
#
# A host file is hardware + flags. The module list lives in flake.nix and is
# the same for every machine, so there is no import list to get wrong here.
{
  imports = [
    ./disk.nix
    ./hardware-configuration.nix
  ];

  # Features that are not universal. Everything else - desktop, shell, fonts,
  # packages, default applications, maintenance - is on by default.
  # my.nvidia.enable = true;   # only on a machine with an NVIDIA card:
                               # multi-GB CUDA/driver closure.
  # my.gaming.enable = true;

  # CHANGE ME to the NixOS release you are installing this machine with,
  # e.g. "26.11". It is a record of the install, not a version to keep
  # current - never bump it afterwards.
  system.stateVersion = "26.05";

  # Per-host overrides go here and need no mkForce, because the base layer
  # states its opinions with mkDefault. For example:
  #   boot.kernelPackages = pkgs.linuxPackages;        # LTS instead of latest
  #   time.timeZone = "Europe/Amsterdam";
  #   zramSwap.memoryPercent = 50;                     # small-RAM machine
  #   boot.loader.systemd-boot.configurationLimit = 5; # small ESP
}
