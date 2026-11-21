# Steam. Opt-in per host: my.gaming.enable = true;
{ config, pkgs, lib, ... }:

let
  cfg = config.my.gaming;
in
{
  options.my.gaming.enable = lib.mkEnableOption "Steam, gamemode and mangohud";

  config = lib.mkIf cfg.enable {
    # Proton needs the 32-bit graphics stack. This used to be inherited from
    # modules/nvidia.nix by import order, which meant enabling gaming on an
    # AMD-only host silently produced a Steam that could not launch anything.
    # Set it here too - mkDefault, and nvidia.nix sets the same values, so the
    # two agree instead of conflicting.
    hardware.graphics = {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };

    programs.steam = {
      enable = true;
      # mkDefault: flip any of these on from the host file if you use the
      # feature - no need to edit this module.
      remotePlay.openFirewall = lib.mkDefault false;
      dedicatedServer.openFirewall = lib.mkDefault false;
      localNetworkGameTransfers.openFirewall = lib.mkDefault false;
    };

    # Lets Proton/Wine games raise their own file-descriptor and memory limits.
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      # System-wide on purpose: Steam runs games inside its own sandbox,
      # which reliably sees system packages.
      mangohud   # in-game perf overlay; run games with `mangohud %command%`
      # protonup-qt is a personal app (installs Proton into ~/.steam):
      # home/apps.nix.
    ];
  };
}
