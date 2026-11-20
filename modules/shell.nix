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

    shellAliases = {
      ls = "eza --group-directories-first";
      ll = "eza -l --git --group-directories-first";
      la = "eza -la --git --group-directories-first";
      lt = "eza --tree --level=2";

      # This config. `nrs` is the one you'll type most.
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config";
      nrb = "sudo nixos-rebuild build  --flake ~/nixos-config";
      nfu = "cd ~/nixos-config && nix flake update";
      ngc = "sudo nix-collect-garbage --delete-older-than 30d";
    };

    interactiveShellInit = ''
      # fzf-tab replaces zsh's completion menu with an fzf picker. It needs
      # compdef to exist, so make sure the completion system is loaded first.
      if ! whence compdef > /dev/null 2>&1; then
        autoload -Uz compinit && compinit
      fi
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Show a preview pane when completing paths.
      zstyle ':fzf-tab:complete:*:*' fzf-preview \
        'if [[ -d $realpath ]]; then eza --tree --level=1 --color=always $realpath;
         else bat --color=always --style=plain --line-range=:40 $realpath 2>/dev/null; fi'
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':completion:*' menu no          # required: fzf-tab draws its own
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Sensible word boundaries for Ctrl-W.
      autoload -U select-word-style && select-word-style bash
    '';
  };

  users.defaultUserShell = pkgs.zsh;

  # Create the history directory. %h expands to each user's home.
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/zsh 0700 - - -"
  ];

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = lib.concatStrings [
        "$directory" "$git_branch" "$git_status" "$nix_shell"
        "$python" "$rust" "$nodejs" "$cmd_duration" "$line_break" "$character"
      ];
      directory.truncation_length = 3;
      directory.truncate_to_repo = false;
      git_status.disabled = false;
      nix_shell.format = "[$symbol$name]($style) ";
      nix_shell.symbol = "❄ ";
      cmd_duration.min_time = 2000;
      character.success_symbol = "[❯](bold green)";
      character.error_symbol = "[❯](bold red)";
    };
  };

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
