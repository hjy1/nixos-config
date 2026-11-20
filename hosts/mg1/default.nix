# MAINGEAR MG-1 MK.II - desktop, Ryzen iGPU + RTX 50-series, btrfs on NVMe.
#
# This host predates disko (it was installed with the graphical ISO), so it
# keeps the generated hardware-configuration.nix and has no disk.nix.
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/shell.nix
    ../../modules/gaming.nix
  ];
}
