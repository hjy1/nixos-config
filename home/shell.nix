# My interactive shell. zsh itself (installed, in /etc/shells, the login
# shell) is a system fact in modules/shell.nix; everything that makes it
# pleasant is mine and lives here.
#
# The functional wiring is declarative. Aliases, fzf-tab previews and other
# things you change on a whim stay in dotfiles/zsh/local.zsh - no rebuild.
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;   # don't record a line identical to the previous
      ignoreSpace = true;  # leading space keeps a command out of history
      share = true;        # live across open shells
      extended = true;     # timestamps
    };

    setOptions = [
      "AUTO_CD"              # `..` instead of `cd ..`
      "AUTO_PUSHD"           # every cd pushes onto the dir stack
      "PUSHD_IGNORE_DUPS"
      "INTERACTIVE_COMMENTS" # allow # comments when typing interactively
      "NO_BEEP"
    ];

    initContent = lib.mkMerge [
      # fzf-tab replaces the completion menu with an fzf picker. It must load
      # AFTER compinit (order 570) and BEFORE anything that wraps ZLE widgets
      # - autosuggestions is 700. home-manager's `plugins` list sources at
      # 900, too late, so it is placed by hand.
      (lib.mkOrder 650 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')

      ''
      # Required for fzf-tab to work at all - it draws its own menu.
      zstyle ':completion:*' menu no

      # Sensible word boundaries for Ctrl-W.
      autoload -U select-word-style && select-word-style bash

      # The mutable half: aliases, previews, colours. Edit live.
      [ -r "${config.xdg.configHome}/zsh/local.zsh" ] && source "${config.xdg.configHome}/zsh/local.zsh"
    ''
    ];
  };

  # zsh does not create the history file's directory itself.
  home.activation.zshHistoryDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.dataHome}/zsh"
  '';

  # Enabled with no `settings`: the prompt lives in dotfiles/starship.toml,
  # linked into place by home/dotfiles.nix. Declaring it here would cost a
  # rebuild per symbol change.
  programs.starship.enable = true;

  programs.fzf.enable = true;     # Ctrl-R history, Ctrl-T files, Alt-C cd
  programs.zoxide.enable = true;  # `z <partial>` jumps to frecent dirs

  # Entering a directory with a .envrc loads that project's toolchain - the
  # mechanism that keeps per-language tooling out of this config entirely.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  home.packages = with pkgs; [
    eza      # ls  - aliased in local.zsh
    bat      # cat - fzf-tab previews
    fd
    ripgrep
    zsh-completions
    uv       # Python project/venv manager
    python3  # for one-off scripts
  ];
}
