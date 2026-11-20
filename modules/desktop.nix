# niri (scrollable-tiling Wayland compositor) + Dux Shell / DMS.
#
# GNOME is intentionally still here as a login-screen fallback. Once niri
# is confirmed working, see the "STRIPPING GNOME" note at the bottom.
{ config, pkgs, lib, ... }:

{
  # The nixpkgs niri module handles portals, gnome-keyring, the session
  # package, and pins defaultSession = "niri" (via mkDefault).
  programs.niri.enable = true;

  # Fallback desktop. Pick GNOME at the GDM session picker if niri misbehaves.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Dux Shell (formerly DankMaterialShell). The nixpkgs attribute is now
  # `dux-shell`; upstream rebranded to duxlabs.dev, so the store path reads
  # "dux-shell" and the CLI is `dms`. There is no NixOS module for it, but
  # the package ships a systemd user unit, which is the clean way in.
  systemd.packages = [ pkgs.dux-shell ];
  systemd.user.services.dms = {
    overrideStrategy = "asDropin";
    wantedBy = [ "graphical-session.target" ];
  };

  environment.systemPackages = with pkgs; [
    dux-shell
    quickshell          # the QML runtime DMS is built on
    xwayland-satellite  # run X11 apps under niri
    matugen             # DMS uses this for wallpaper-derived theming
    wl-clipboard
    brightnessctl
    playerctl
    cava
  ];

  # Trim the GNOME app bundle you didn't ask for. Safe to prune while
  # keeping GNOME itself as a fallback.
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    gnome-maps
    gnome-software
    totem
    epiphany
    geary
    simple-scan
    yelp
  ];

  # STRIPPING GNOME, once niri is proven:
  #   services.desktopManager.gnome.enable = false;
  # Note that niri still depends on xdg-desktop-portal-gnome and nautilus
  # for its portals and file chooser, so a few GNOME components stay in the
  # closure by design. That is expected, not leftover cruft.
  #
  # You can also set programs.niri.useNautilus = false; to drop nautilus and
  # fall back to the GTK file chooser.
}
