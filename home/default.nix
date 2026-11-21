# MINE - everything that is about me rather than about the machine.
#
# Loaded by home-manager from modules/user.nix. A second user on this machine
# would get none of this unless they import it too - which is the point.
#
#   shell.nix     zsh plugins, prompt, fzf, zoxide, direnv
#   git.nix       git identity, gh
#   apps.nix      my applications and default-app choices
#   dotfiles.nix  links into dotfiles/, first-login clone, auto-sync to GitHub
{ ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./apps.nix
    ./dotfiles.nix
  ];

  # XDG base directories. Also moves zsh's dotfiles to ~/.config/zsh.
  xdg.enable = true;

  # Which home-manager release first managed THIS user's home. Like the
  # system stateVersion: a record, never bumped.
  home.stateVersion = "26.11";
}
