# My interactive shell. zsh itself (installed, in /etc/shells, the login
# shell) is a system fact in modules/shell.nix; everything that makes it
# pleasant is mine and lives here - plugins, aliases, prompt. Change, `hms`,
# then `exec zsh`.
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

      # fzf-tab: preview directories as trees, files with bat.
      zstyle ':fzf-tab:complete:*:*' fzf-preview \
        'if [[ -d $realpath ]]; then eza --tree --level=1 --color=always $realpath;
         else bat --color=always --style=plain --line-range=:40 $realpath 2>/dev/null; fi'
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    ''
    ];

    shellAliases = {
      ls = "eza --group-directories-first";
      ll = "eza -l --git --group-directories-first";
      la = "eza -la --git --group-directories-first";
      lt = "eza --tree --level=2";

      # This config. $NIXOS_REPO comes from me.nix (home/default.nix).
      #   nrs = the machine: modules/, hosts/  (sudo - like pacman on Arch)
      #   hms = me: home/                      (no sudo)
      # -b keeps a backup of any file in the way of a new link.
      nrs = ''sudo nixos-rebuild switch --flake "$NIXOS_REPO"'';
      nrb = ''sudo nixos-rebuild build  --flake "$NIXOS_REPO"'';
      hms = ''home-manager switch -b hm-bak --flake "$NIXOS_REPO"'';
      nfu = ''cd "$NIXOS_REPO" && nix flake update'';
      ngc = "sudo nix-collect-garbage --delete-older-than 30d";
      cfg = ''cd "$NIXOS_REPO"'';
    };
  };

  # zsh does not create the history file's directory itself.
  home.activation.zshHistoryDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.dataHome}/zsh"
  '';

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$directory$git_branch$git_status$nix_shell$python$rust$nodejs$cmd_duration$line_break$character";

      directory = {
        truncation_length = 3;
        truncate_to_repo = false;
      };
      git_status.disabled = false;
      nix_shell = {
        format = "[$symbol$name]($style) ";
        symbol = "❄ ";
      };
      cmd_duration.min_time = 2000;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

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
    eza      # ls  - see shellAliases above
    bat      # cat - fzf-tab previews
    fd
    ripgrep
    zsh-completions
    uv       # Python project/venv manager
    python3  # for one-off scripts
  ];
}
