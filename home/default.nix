# MINE - everything that is about me rather than the machine.
#
# Standalone home-manager: applied by `hms` (home-manager switch) as my user,
# NO sudo. The rule for what goes here vs modules/: if on Arch it would need
# `sudo pacman` / `systemctl enable`, it is the machine (modules/, `nrs`).
# If on Arch you would just edit a file in your home directory, it is here.
#
# home-manager owns every config file of mine. Edit here, `hms`.
#
#   shell.nix    zsh: plugins, aliases, history; starship, fzf, zoxide, direnv
#   git.nix      git identity, gh
#   apps.nix     my applications and default-app choices
#   ghostty.nix  terminal settings
#   niri.nix     installs niri/config.kdl (validated)
#   dms.nix      DMS settings - the one live, app-written file - and `dsync`
{ me, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./apps.nix
    ./ghostty.nix
    ./niri.nix
    ./dms.nix
  ];

  # The repo path, for the nrs/hms aliases and scripts.
  home.sessionVariables.NIXOS_REPO = me.repoPath;

  home.username = me.name;
  home.homeDirectory = "/home/${me.name}";

  # Installs the `home-manager` command itself, so `hms` keeps working after
  # the first bootstrap (`nix run home-manager -- switch --flake ...`).
  programs.home-manager.enable = true;

  # XDG base directories. Also moves zsh's dotfiles to ~/.config/zsh.
  xdg.enable = true;

  # Which home-manager release first managed THIS user's home. Like the
  # system stateVersion: a record, never bumped.
  home.stateVersion = "26.11";
}
