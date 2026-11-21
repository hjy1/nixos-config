# DMS (Dux Shell) settings - the one deliberate exception to "home-manager
# generates it".
#
# DMS saves home/dms/settings.json itself whenever you change something in
# its Settings UI (Mod+,). A file home-manager generates is read-only, so DMS
# could not save. Instead home-manager links ~/.config/dms/settings.json to
# the live file in this repo (mkOutOfStoreSymlink): DMS writes through the
# link (verified), and the change is a repo change.
#
# `dsync` commits and pushes it. Everything else in home/ changes only when
# you edit it, so it gets ordinary commits.
{ config, me, pkgs, lib, ... }:

let
  file = "home/dms/settings.json";

  dsync = pkgs.writeShellApplication {
    name = "dsync";
    runtimeInputs = with pkgs; [ git openssh coreutils gnugrep libnotify ];
    text = ''
      cd ${lib.escapeShellArg me.repoPath}
      if [ "$(git branch --show-current)" != main ]; then
        echo "dsync: not on main - skipping" >&2; exit 1
      fi

      git add -- ${file}
      if git diff --cached --quiet -- ${file}; then
        echo "dsync: DMS settings unchanged"
      else
        # Public repo: refuse anything that looks like a credential.
        if git diff --cached -U0 -- ${file} | grep -E '^\+' | grep -qiE \
             'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|"?(password|passwd|secret|api[_-]?key|token)"?[[:space:]]*[:=]'; then
          git reset -q -- ${file}
          notify-send -u critical "DMS settings NOT synced" "A change looks like a secret."
          echo "dsync: refused - a change looks like a secret. Review: git diff -- ${file}" >&2
          exit 1
        fi
        # Pathspec commit: only this file, even if other files are staged.
        git commit -q -m "dms: settings from $(uname -n)" -- ${file}
        echo "dsync: committed DMS settings"
      fi

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
  xdg.configFile."dms/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${me.repoPath}/${file}";

  home.packages = [ dsync ];
}
