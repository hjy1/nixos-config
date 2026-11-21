# zsh as the login shell, plus the usual interactive-shell furniture.
#
# All of this uses nixpkgs' own NixOS modules - no extra flake inputs. The
# tradeoff: these write /etc/zshrc system-wide rather than ~/.zshrc per user.
# For per-user dotfiles you'd want home-manager; see the note at the bottom.
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    histSize = 50000;
    # zsh does NOT create the parent directory for histFile - without the
    # tmpfiles rule below, history silently fails to persist.
    histFile = "$HOME/.local/share/zsh/history";

    setOptions = [
      "HIST_IGNORE_DUPS"        # don't record a line identical to the previous
      "HIST_IGNORE_SPACE"       # leading space keeps a command out of history
      "SHARE_HISTORY"           # history shared live between open shells
      "EXTENDED_HISTORY"        # record timestamps
      "AUTO_CD"                 # `..` instead of `cd ..`
      "AUTO_PUSHD"              # every cd pushes onto the dir stack
      "PUSHD_IGNORE_DUPS"
      "INTERACTIVE_COMMENTS"    # allow # comments when typing interactively
      "NO_BEEP"
    ];

    # starship owns the prompt, so drop the module's default prompt.
    promptInit = "";

    # NO shellAliases here on purpose - aliases change on a whim and would
    # cost a rebuild each time. They live in dotfiles/zsh/local.zsh.

    interactiveShellInit = ''
      # fzf-tab replaces zsh's completion menu with an fzf picker. It needs
      # compdef to exist, so make sure the completion system is loaded first.
      if ! whence compdef > /dev/null 2>&1; then
        autoload -Uz compinit && compinit
      fi
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Required for fzf-tab to work at all - it draws its own menu. This is
      # functional, not cosmetic, so it stays declarative.
      zstyle ':completion:*' menu no

      # Sensible word boundaries for Ctrl-W.
      autoload -U select-word-style && select-word-style bash

      # Everything mutable - aliases, fzf-tab previews, colours - lives here.
      # The hook is declarative and permanent; the contents are yours to edit
      # without ever rebuilding.
      [ -r "$HOME/.config/zsh/local.zsh" ] && source "$HOME/.config/zsh/local.zsh"
    '';
  };

  # NOT mkDefault, deliberately. nixpkgs' bash.nix already claims this with
  # mkDefault pkgs.bashInteractive, so a second mkDefault here is two
  # definitions at the same priority with different values - which is an
  # eval error, not a tie-break. A plain definition (priority 100) beats
  # both, and a host that wants fish still overrides it with mkForce.
  users.defaultUserShell = pkgs.zsh;

  # Directories, and symlinks from ~/.config into the repo.
  #
  # The repo path below is load-bearing: clone this repo to ~/nixos-config on
  # every machine, or these four links dangle.
  #
  # The LINKS are declarative - a fresh machine gets them automatically, no
  # manual `ln -sf`. The TARGETS are plain mutable files in the repo, so you
  # edit them live, git tracks the change, and nothing rebuilds.
  #
  # `L` only creates the link if nothing is there, so it will never clobber a
  # real file you put in its place.
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/zsh 0700 - - -"
    "d %h/.config/zsh      0755 - - -"
    "d %h/.config/niri     0755 - - -"
    "d %h/.config/ghostty  0755 - - -"
    "L %h/.config/zsh/local.zsh    - - - - %h/nixos-config/dotfiles/zsh/local.zsh"
    "L %h/.config/starship.toml    - - - - %h/nixos-config/dotfiles/starship.toml"
    "L %h/.config/niri/config.kdl  - - - - %h/nixos-config/dotfiles/niri/config.kdl"
    "L %h/.config/ghostty/config   - - - - %h/nixos-config/dotfiles/ghostty/config"
  ];

  # enable only - NO `settings`. Declaring the prompt here would mean a
  # rebuild every time you change a symbol. The module only sets
  # STARSHIP_CONFIG when ~/.config/starship.toml is absent, and the tmpfiles
  # link above makes sure it never is, so dotfiles/starship.toml always wins.
  programs.starship.enable = true;

  programs.fzf = {
    keybindings = true;      # Ctrl-R history, Ctrl-T files, Alt-C cd
    fuzzyCompletion = true;  # ** trigger
  };

  programs.zoxide.enable = true;   # `z <partial>` jumps to frecent dirs

  # direnv + nix-direnv: entering a directory with a .envrc loads that
  # project's toolchain automatically. This is the mechanism that keeps
  # per-language tooling OUT of your system config - see the note below.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  environment.systemPackages = with pkgs; [
    eza
    bat
    fd
    ripgrep
    zsh-completions
    uv            # Python project/venv manager - owns its own lockfiles
    python3       # a system interpreter for one-off scripts
  ];

  # WHY NOT home-manager (yet):
  # These modules generate /etc/zshrc, which is system-wide and cannot vary
  # per user. That is fine for a single-user desktop. home-manager would let
  # you generate ~/.zshrc, ~/.config/starship.toml and ~/.config/niri/config.kdl
  # as real per-user files - worth adding when you want that, not before.
}
