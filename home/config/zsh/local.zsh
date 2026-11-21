# Mutable shell config: aliases and interactive cosmetics.
#
# This IS ~/.config/zsh/local.zsh (home-manager links it here), so edit
# either path. Sourced by ~/.config/zsh/.zshrc, which home/shell.nix
# generates. A new shell picks changes up, or `exec zsh` in the current one.
#
# Aliases and cosmetics go here. Which plugins load, and history, are in
# home/shell.nix (change, then `hms`).

# ---------------------------------------------------------------- aliases ---
alias ls='eza --group-directories-first'
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'

# This config. $NIXOS_REPO comes from me.nix (home/default.nix); the
# fallback only matters before the first `hms`. No `#<host>` needed:
# flake.nix names every host after its directory.
# nrs = the machine (sudo, like pacman/systemctl on Arch): modules/, hosts/
# hms = me (no sudo): home/*.nix  -  -b keeps a backup of any file that is
#       in the way of a new link instead of failing.
alias nrs='sudo nixos-rebuild switch --flake "${NIXOS_REPO:-$HOME/nixos-config}"'
alias nrb='sudo nixos-rebuild build  --flake "${NIXOS_REPO:-$HOME/nixos-config}"'
alias hms='home-manager switch -b hm-bak --flake "${NIXOS_REPO:-$HOME/nixos-config}"'
alias nfu='cd "${NIXOS_REPO:-$HOME/nixos-config}" && nix flake update'
alias ngc='sudo nix-collect-garbage --delete-older-than 30d'
alias cfg='cd "${NIXOS_REPO:-$HOME/nixos-config}"'

# ------------------------------------------------------- fzf-tab cosmetics ---
# Preview pane contents. Purely taste; tweak at will.
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -d $realpath ]]; then eza --tree --level=1 --color=always $realpath;
   else bat --color=always --style=plain --line-range=:40 $realpath 2>/dev/null; fi'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
