# The user account, and the seam between the two halves of this repo:
#
#   SYSTEM  (modules/, configuration.nix)  - true for the machine and every
#           user on it: boot, drivers, desktop session, fonts, zsh as the
#           login shell, base admin tools.
#   MINE    (home/, via home-manager)      - true for me: shell plugins and
#           prompt, git identity, my apps, default apps, the dotfile links.
#
# Identity values come from ../me.nix; nothing here hard-codes a name.
{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.my;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.my = {
    user = {
      name = mkOption { type = types.str; description = "Login name."; };
      fullName = mkOption { type = types.str; };
      email = mkOption { type = types.str; description = "Git identity."; };
      github = mkOption { type = types.str; description = "GitHub account that owns the repo."; };
    };

    repo = {
      path = mkOption {
        type = types.str;
        default = "/home/${cfg.user.name}/nixos-config";
        description = ''
          Where this repo is checked out. Every dotfile link points here, so
          it is defined once and read everywhere.
        '';
      };
      url = mkOption {
        type = types.str;
        default = "https://github.com/${cfg.user.github}/nixos-config.git";
        description = ''
          Cloned automatically on first login if repo.path is missing. HTTPS
          so a fresh machine needs no SSH key to fetch a public repo; the
          push URL is switched to SSH after cloning.
        '';
      };
    };
  };

  config = {
    users.users.${cfg.user.name} = {
      isNormalUser = true;
      description = cfg.user.fullName;
      extraGroups = [ "networkmanager" "wheel" ];
      # zsh is the login shell - a system fact, so it lives in
      # modules/shell.nix (users.defaultUserShell) rather than here.
    };

    home-manager = {
      # One package set for system and user: same nixpkgs, same allowUnfree,
      # no second evaluation.
      useGlobalPkgs = true;
      # User packages land in /etc/profiles/per-user/<name>, which is on
      # PATH and XDG_DATA_DIRS for every session - including niri's.
      useUserPackages = true;
      # A real file where home-manager wants to put a link is moved aside to
      # <file>.hm-bak instead of aborting the whole switch.
      backupFileExtension = "hm-bak";

      users.${cfg.user.name} = import ../home;
    };
  };
}
