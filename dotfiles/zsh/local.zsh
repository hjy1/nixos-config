# Mutable shell config: aliases and interactive cosmetics.
#
# Sourced from /etc/zshrc. Edit freely - a new shell picks changes up, or
# `exec zsh` in the current one. NEVER requires nixos-rebuild.
#
# Keep anything here that you might change on a whim. Things that must be
# true for the shell to FUNCTION belong in modules/shell.nix instead.

# ---------------------------------------------------------------- aliases ---
alias ls='eza --group-directories-first'
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'

# This config
alias nrs='sudo nixos-rebuild switch --flake ~/nixos-config'
alias nrb='sudo nixos-rebuild build  --flake ~/nixos-config'
alias nfu='cd ~/nixos-config && nix flake update'
alias ngc='sudo nix-collect-garbage --delete-older-than 30d'
alias cfg='cd ~/nixos-config'

# ------------------------------------------------------- fzf-tab cosmetics ---
# Preview pane contents. Purely taste; tweak at will.
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -d $realpath ]]; then eza --tree --level=1 --color=always $realpath;
   else bat --color=always --style=plain --line-range=:40 $realpath 2>/dev/null; fi'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
