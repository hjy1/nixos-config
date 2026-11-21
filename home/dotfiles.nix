# dotfiles/ <-> ~/.config, and dotfiles/ <-> GitHub.
#
#   LINKS. Each file below becomes ~/.config/<x> -> <repo>/dotfiles/<y>.
#   mkOutOfStoreSymlink points at the live checkout, not a read-only store
#   copy, so edits - by you, or by an app's own settings UI - land straight
#   in the repo and apply with no command at all. The links themselves are
#   created by `hms`.
#
#   SYNC. `dsync` (the `dotfiles-sync` command) commits whatever changed
#   under dotfiles/ and pushes it. Run by hand. Only dotfiles/: Nix changes
#   are structural and get a deliberate, hand-written commit.
{ config, me, pkgs, lib, ... }:

let
  repo = me.repoPath;
  live = path: config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/${path}";

  # ~/.config path = dotfiles/ path. To add one: put the file in dotfiles/,
  # add a line here, `hms` once. After that it is edit-and-forget.
  links = {
    "niri/config.kdl" = "niri/config.kdl";
    "ghostty/config" = "ghostty/config";
    "starship.toml" = "starship.toml";
    "zsh/local.zsh" = "zsh/local.zsh";
    # Written by DMS's own Settings UI - verified to write through the link,
    # so clicking a setting is a repo change.
    "dms/settings.json" = "dms/settings.json";
  };

  notify = "${pkgs.libnotify}/bin/notify-send --app-name=dotfiles";

  sync = pkgs.writeShellApplication {
    name = "dotfiles-sync";
    runtimeInputs = with pkgs; [ git openssh coreutils gnugrep ];
    text = ''
      cd ${lib.escapeShellArg repo}
      if [ "$(git branch --show-current)" != main ]; then
        echo "dsync: not on main - skipping" >&2; exit 1
      fi

      git add -A -- dotfiles
      if git diff --cached --quiet -- dotfiles; then
        echo "dsync: nothing changed under dotfiles/"
      else
        # Public repo: refuse to publish anything that looks like a
        # credential. The change stays local and you are told.
        if git diff --cached -U0 -- dotfiles | grep -E '^\+' | grep -qiE \
             'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|"?(password|passwd|secret|api[_-]?key|token)"?[[:space:]]*[:=]'; then
          git reset -q -- dotfiles
          ${notify} -u critical "Dotfiles NOT synced" "A change under dotfiles/ looks like a secret."
          echo "dsync: refused - a change looks like a secret. Review: git diff -- dotfiles" >&2
          exit 1
        fi
        git diff --cached --stat -- dotfiles
        # Pathspec commit: only dotfiles/, even if other files are staged.
        git commit -q -m "dotfiles: sync from $(uname -n)" -- dotfiles
      fi

      # Push if ahead; if another machine pushed first, rebase onto it.
      git fetch -q origin main
      if [ -z "$(git rev-list origin/main..main)" ]; then
        echo "dsync: up to date with GitHub"; exit 0
      fi
      git pull -q --rebase --autostash origin main
      git push -q origin main
      echo "dsync: pushed"
    '';
  };
in
{
  xdg.configFile = lib.mapAttrs (_: target: { source = live target; }) links;

  home.packages = [ sync ];

  # The repo path, for aliases and scripts - so nothing in dotfiles/ has to
  # hard-code where the checkout lives.
  home.sessionVariables.NIXOS_REPO = repo;
}
