# niri (scrollable-tiling Wayland compositor) + Dux Shell / DMS.
#
# GNOME is intentionally still here as a login-screen fallback. Once niri
# is confirmed working, see the "STRIPPING GNOME" note at the bottom.
#
# Not flag-gated: every host so far is a workstation. The day a headless or
# server host appears, give this module a my.desktop.enable flag exactly the
# way modules/nvidia.nix does - do not go back to curating import lists.
{ config, pkgs, lib, me, ... }:

{
  # The nixpkgs niri module handles portals, gnome-keyring, the session
  # package, and pins defaultSession = "niri" (via mkDefault).
  programs.niri.enable = true;

  # Fallback desktop. Pick GNOME at the GDM session picker if niri misbehaves.
  services.displayManager.gdm.enable = lib.mkDefault true;
  services.desktopManager.gnome.enable = lib.mkDefault true;

  # Dux Shell (formerly DankMaterialShell; the CLI is still `dms`).
  #
  # Use the nixpkgs module, not a hand-rolled unit. The first version of this
  # file did `systemd.packages = [ dux-shell ]` plus a wantedBy override, and
  # DMS crash-looped on login with `exec: "qs": executable file not found`:
  # NixOS gives every systemd.user.services entry a minimal PATH, which
  # hides quickshell. The module sets `path = mkForce [ ]` so the unit
  # inherits the session PATH, and also pulls in quickshell, matugen, cava,
  # accounts-daemon (user avatar) and i2c (DDC monitor brightness).
  programs.dux-shell.enable = true;

  # DDC/CI brightness for external monitors goes through /dev/i2c-*, which
  # hardware.i2c (enabled by the module above) gives to the i2c group.
  users.users.${me.name}.extraGroups = [ "i2c" ];

  # Make Electron/Chromium apps run as native Wayland clients instead of
  # going through XWayland. Without this, VSCode and bilibili (both Electron)
  # render blurry on HiDPI, ignore fractional scaling, and have worse input
  # latency under niri. Single highest-value line in this file.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # dux-shell, quickshell, matugen and cava come from programs.dux-shell.

    # X11 apps under niri. niri (>= 25.08) starts this itself on demand and
    # exports DISPLAY - it only has to be on PATH. Do NOT also spawn it from
    # config.kdl: that runs a second, useless copy.
    xwayland-satellite

    # GTK3 theme that DMS recolours from the wallpaper (`dms doctor` flags
    # it as missing). Being installed is Tier 1; selecting it is DMS's job.
    adw-gtk3

    wl-clipboard
    brightnessctl
    playerctl
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
  #   services.desktopManager.gnome.enable = false;   # no mkForce needed
  # Note that niri still depends on xdg-desktop-portal-gnome and nautilus
  # for its portals and file chooser, so a few GNOME components stay in the
  # closure by design. That is expected, not leftover cruft.
  #
  # You can also set programs.niri.useNautilus = false; to drop nautilus and
  # fall back to the GTK file chooser.
}
