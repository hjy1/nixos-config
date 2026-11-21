# gear - MAINGEAR MG-1 MK.II desktop, Ryzen iGPU + RTX 50-series, btrfs on NVMe.
#
# This host predates disko (it was installed with the graphical ISO), so it
# keeps the generated hardware-configuration.nix and has no disk.nix.
#
# Note what is NOT here: the module list. Every module in modules/ is imported
# for every host by flake.nix, so a host file is hardware + flags. The
# hostname comes from this directory's name.
{
  imports = [
    ./hardware-configuration.nix
  ];

  my.nvidia.enable = true;   # RTX 50-series (Blackwell)
  my.gaming.enable = true;

  # Which NixOS release first installed THIS machine. Per-host by definition.
  # Do NOT change it, even though the system now tracks unstable.
  system.stateVersion = "26.05";
}
