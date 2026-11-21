# dotfiles/ <-> ~/.config, and dotfiles/ <-> GitHub.
#
#   1. LINKS. Each file below becomes ~/.config/<x> -> <repo>/dotfiles/<y>.
#      mkOutOfStoreSymlink points at the live checkout, not a read-only store
#      copy, so edits (by you, or by the app's own settings UI) land straight
#      in the repo and apply without a rebuild.
#   2. CLONE. On a fresh machine the repo is cloned on first login if it is
#      missing, so the links resolve with no manual step.
#   3. SYNC. `dotfiles-sync` (alias `dsync`) commits whatever changed under
#      dotfiles/ and pushes it - run by hand, no timer. Only dotfiles/: Nix
#      changes are structural and get a deliberate, hand-written commit.
{ config, osConfig, pkgs, lib, ... }:

let
  repo = osConfig.my.repo.path;
  live = path: config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/${path}";

  # Dotfiles linked into ~/.config. To add one: put the file in dotfiles/,
  # add a line here, rebuild once. After that it is edit-and-forget.
  links = {
    "niri/config.kdl" = "niri/config.kdl";
    "ghostty/config" = "ghostty/config";
    "starship.toml" = "starship.toml";
    "zsh/local.zsh" = "zsh/local.zsh";
    # Rewritten by the apps' own settings UIs - both write through the link
    # (verified for DMS), so clicking a setting is a repo change.
    "dms/settings.json" = "dms/settings.json";
    "Code/User/settings.json" = "vscode/settings.json";
    "Code/User/keybindings.json" = "vscode/keybindings.json";
  };

  notify = "${pkgs.libnotify}/bin/notify-send --app-name=dotfiles";

  sync = pkgs.writeShellApplication {
    name = "dotfiles-sync";
    runtimeInputs = with pkgs; [ git openssh coreutils gnugrep vscode ];
    text = ''
      cd ${lib.escapeShellArg repo} 2>/dev/null || exit 0
      [ -d .git ] || exit 0
      # Never interfere with something you are doing by hand.
      [ "$(git branch --show-current)" = main ] || exit 0
      [ -e .git/rebase-merge ] || [ -e .git/rebase-apply ] || [ -e .git/MERGE_HEAD ] && exit 0

      # VS Code extensions are installed code, not a file - capture the list.
      if exts=$(code --list-extensions 2>/dev/null); then
        printf '%s\n' "$exts" > dotfiles/vscode/extensions.txt
      fi

      git add -A -- dotfiles
      if ! git diff --cached --quiet -- dotfiles; then
        # Public repo: refuse to auto-publish anything that looks like a
        # credential. The change stays local and you get told.
        if git diff --cached -U0 -- dotfiles | grep -E '^\+' | grep -qiE \
             'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|"?(password|passwd|secret|api[_-]?key|token)"?[[:space:]]*[:=]'; then
          git reset -q -- dotfiles
          ${notify} -u critical "Dotfiles NOT synced" "A change under dotfiles/ looks like a secret. Review: git -C ${repo} diff"
          exit 1
        fi
        # Pathspec commit: only dotfiles/, even if other files are staged.
        git commit -q -m "dotfiles: sync from $(uname -n)" -- dotfiles
      fi

      # Push if ahead; if the remote moved (another machine synced), rebase.
      git fetch -q origin main || exit 0
      [ -n "$(git rev-list origin/main..main)" ] || exit 0
      if ! git push -q origin main 2>/dev/null; then
        if git pull -q --rebase --autostash origin main && git push -q origin main; then :; else
          git rebase --abort 2>/dev/null || true
          ${notify} -u critical "Dotfiles sync conflict" "Resolve by hand in ${repo}"
          exit 1
        fi
      fi
    '';
  };
in
{
  xdg.configFile = lib.mapAttrs (_: target: { source = live target; }) links;

  home.packages = [ sync ];   # `dotfiles-sync`, aliased to `dsync`

  # The repo path, for aliases and scripts - so nothing in dotfiles/ has to
  # hard-code where the checkout lives.
  home.sessionVariables.NIXOS_REPO = repo;

  systemd.user.services.nixos-config-clone = {
    Unit = {
      Description = "Clone nixos-config on first login so dotfile links resolve";
      ConditionPathExists = "!${repo}/.git";
    };
    Service = {
      Type = "oneshot";
      # User units cannot wait for network-online.target, so retry instead.
      Restart = "on-failure";
      RestartSec = 30;
      ExecStart = toString (pkgs.writeShellScript "nixos-config-clone" ''
        set -eu
        ${pkgs.git}/bin/git clone ${lib.escapeShellArg osConfig.my.repo.url} ${lib.escapeShellArg repo}
        # Fetch anonymously over HTTPS, push over SSH once a key exists.
        ${pkgs.git}/bin/git -C ${lib.escapeShellArg repo} remote set-url --push origin \
          git@github.com:${osConfig.my.user.github}/nixos-config.git
      '');
    };
    Install.WantedBy = [ "default.target" ];
  };

  # The other half of the extensions list: install anything listed but
  # missing. Idempotent, so it is safe on every login; a fresh machine gets
  # the whole set.
  systemd.user.services.vscode-extensions-restore = {
    Unit = {
      Description = "Install VS Code extensions listed in dotfiles/vscode/extensions.txt";
      ConditionPathExists = "${repo}/dotfiles/vscode/extensions.txt";
      After = [ "nixos-config-clone.service" ];
    };
    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 60;
      ExecStart = toString (pkgs.writeShellScript "vscode-extensions-restore" ''
        set -eu
        have=$(${pkgs.vscode}/bin/code --list-extensions)
        while read -r ext; do
          [ -n "$ext" ] || continue
          printf '%s\n' "$have" | ${pkgs.gnugrep}/bin/grep -qixF "$ext" \
            || ${pkgs.vscode}/bin/code --install-extension "$ext"
        done < ${lib.escapeShellArg "${repo}/dotfiles/vscode/extensions.txt"}
      '');
    };
    Install.WantedBy = [ "default.target" ];
  };
}
