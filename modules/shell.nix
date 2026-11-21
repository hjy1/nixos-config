# zsh as the login shell - and nothing else.
#
# Plugins, prompt, history, fzf, zoxide and direnv are per-user and live in
# home/shell.nix. Here is only what must be true system-wide for zsh to be a
# valid login shell for every account, root included.
{ config, pkgs, lib, ... }:

{
  # Installs zsh, registers it in /etc/shells, and writes a minimal
  # /etc/zshrc (completion paths, a plain prompt for root).
  programs.zsh = {
    enable = true;
    # home-manager runs compinit for the user; doing it here too would run
    # it twice on every shell start.
    enableGlobalCompInit = false;
  };

  # Completion scripts shipped by system packages (nix, systemctl, git...)
  # live under share/zsh; link them into the system profile so the user's
  # compinit finds them.
  environment.pathsToLink = [ "/share/zsh" ];

  # NOT mkDefault, deliberately. nixpkgs' bash.nix already claims this with
  # mkDefault pkgs.bashInteractive, so a second mkDefault here is two
  # definitions at the same priority with different values - which is an
  # eval error, not a tie-break. A plain definition (priority 100) beats
  # both, and a host that wants fish still overrides it with mkForce.
  users.defaultUserShell = pkgs.zsh;
}
