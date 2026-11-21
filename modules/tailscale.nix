# Tailscale. Opt-in per host: my.tailscale.enable = true;
#
# One-time login after the first switch (interactive, prints a URL):
#   sudo tailscale up
# No auth key is declared here: this repo is public, and a key in the Nix
# store is world-readable anyway. Use authKeyFile + sops-nix/agenix if a host
# ever needs to join unattended.
{ config, lib, ... }:

let
  cfg = config.my.tailscale;
in
{
  options.my.tailscale.enable = lib.mkEnableOption "the Tailscale client";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # Opens the WireGuard UDP port so peers can connect directly instead
      # of falling back to Tailscale's relays.
      openFirewall = true;
      # "client": lets this machine USE exit nodes and subnet routes (sets
      # loose reverse-path filtering). "both" if it should also offer them.
      useRoutingFeatures = lib.mkDefault "client";
      # Let my user drive tailscale without sudo - DMS's Tailscale widget
      # talks to the daemon as the user, and needs this to do anything.
      extraSetFlags = [ "--operator=${config.my.user.name}" ];
    };
  };
}
