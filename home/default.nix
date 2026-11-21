# MINE - everything that is about me rather than the machine.
#
# Standalone home-manager: applied by `hms` (home-manager switch) as my user,
# NO sudo. The rule for what goes here vs modules/: if on Arch it would need
# `sudo pacman` / `systemctl enable`, it is the machine (modules/, `nrs`).
# If on Arch you would just edit a file in your home directory, it is here.
#
# Two kinds of thing, both owned by home-manager:
#   *.nix        what is installed and wired up - change, then `hms`
#   config/      my config files, mirroring ~/.config. Linked LIVE, so you
#                edit ~/.config/<x> normally and the repo already has it.
#
#   shell.nix    zsh plugins + history; starship, fzf, zoxide, direnv
#   git.nix      git identity, gh
#   apps.nix     my applications and default-app choices
#   ghostty.nix  Ghostty package + service (settings: config/ghostty/config)
#   config.nix   links every file in config/ into ~/.config; `dsync`
{ me, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./apps.nix
    ./ghostty.nix
    ./config.nix
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
