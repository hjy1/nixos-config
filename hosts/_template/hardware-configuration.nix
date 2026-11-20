# PLACEHOLDER. nixos-anywhere overwrites this with the real hardware scan via
#   --generate-hardware-config nixos-generate-config <path>
#
# It exists only so the flake can evaluate before the target is probed - the
# disko phase needs a working nixosConfiguration to read disk layout from.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usb_storage" "sd_mod" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
