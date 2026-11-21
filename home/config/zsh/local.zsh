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

# This config, through nh (home/shell.nix). nh finds the repo via
# $NH_FLAKE, the host by hostname and the home by $USER, shows what
# changed, and asks for sudo itself - so no `sudo` in front.
# nrs = the machine (sudo, like pacman/systemctl on Arch): modules/, hosts/
# hms = me (no sudo): home/*.nix  -  -b keeps a backup of any file that is
#       in the way of a new link instead of failing.
# The plain commands still work: sudo nixos-rebuild switch --flake ...
alias nrs='nh os switch'
alias nrb='nh os build'
# nrboot: install for the NEXT boot only, touch nothing running - then
# reboot. Use it instead of nrs when a change would kill your session if
# applied live: login manager (greeter/GDM), GPU driver, kernel.
alias nrboot='nh os boot'
alias hms='nh home switch -b hm-bak'
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
