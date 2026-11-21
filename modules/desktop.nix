# niri (scrollable-tiling Wayland compositor) + Dux Shell / DMS, with GDM
# as the login screen. No GNOME desktop: DMS covers its settings, panels and
# launcher. Recovery if niri ever fails to start: pick an older generation in
# the boot menu, or log in on a TTY (Ctrl+Alt+F3).
#
# Not flag-gated: every host so far is a workstation. The day a headless or
# server host appears, give this module a my.desktop.enable flag exactly the
# way modules/nvidia.nix does - do not go back to curating import lists.
{ config, pkgs, lib, me, ... }:

{
  # The nixpkgs niri module handles portals, gnome-keyring, the session
  # package, and pins defaultSession = "niri" (via mkDefault).
  programs.niri.enable = true;

  services.displayManager.gdm.enable = lib.mkDefault true;

  # What the GNOME desktop used to switch on implicitly, and this desktop
  # still uses. Listed explicitly so removing GNOME did not silently take
  # them away (found by diffing the system with and without GNOME).
  hardware.bluetooth.enable = true;          # DMS Bluetooth panel
  services.power-profiles-daemon.enable = true; # DMS power-profile switcher
  services.upower.enable = true;             # power state DMS reads
  services.udisks2.enable = true;            # mount USB drives
  services.gvfs.enable = true;               # Nautilus trash, network shares
  services.hardware.bolt.enable = true;      # authorise Thunderbolt devices
  services.gnome.at-spi2-core.enable = true; # stops GTK accessibility warnings
  services.avahi = {                         # find network printers
    enable = true;
    nssmdns4 = true;
  };

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
    # it as missing). Installing it is the machine; selecting it is DMS's job.
    adw-gtk3
  ];
}
