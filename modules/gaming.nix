# Steam. Needs hardware.graphics.enable32Bit, which modules/nvidia.nix sets.
{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;      # flip on if you use Remote Play
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
  };

  # Lets Proton/Wine games raise their own file-descriptor and memory limits.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud   # in-game perf overlay; run games with `mangohud %command%`
    protonup-qt
  ];
}
