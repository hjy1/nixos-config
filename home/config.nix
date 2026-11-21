# My config files, edited NORMALLY and captured in the repo.
#
# home/config/ mirrors ~/.config. For every file in it, home-manager makes
#   ~/.config/<path>  ->  <repo>/home/config/<path>
# a link to the LIVE file in this checkout (mkOutOfStoreSymlink), not a
# read-only copy. So you edit ~/.config/ghostty/config the normal way - in any
# editor, or through an app's own settings UI (DMS) - and the change is
# already in the repo: `git diff` shows it, no command applies it.
#
# Adding one - a new app's config, say:
#   dtrack ~/.config/<app>/<file>
# moves the file into home/config/<app>/<file> and runs `hms`, which puts the
# link in its place. Nothing to list here - the directory is the list.
# (Only ~/.config is mirrored; that is where nearly every app keeps config.)
#
# `dsync` commits everything changed under home/config/ and pushes it. First
# it repairs links: an app that saves by REPLACING its file (write a temp
# file, rename it over) turns the link into a plain file, and the repo would
# silently stop seeing changes. dsync copies such a file back into the repo
# and restores the link.
{ config, me, pkgs, lib, ... }:

let
  dir = "home/config";

  # Every file under ./config, as a path relative to it.
  walk = path: prefix:
    lib.concatLists (lib.mapAttrsToList
      (name: type:
        if type == "directory"
        then walk (path + "/${name}") "${prefix}${name}/"
        else [ "${prefix}${name}" ])
      (builtins.readDir path));
  files = walk ./config "";

  dsync = pkgs.writeShellApplication {
    name = "dsync";
    runtimeInputs = with pkgs; [ git openssh coreutils gnugrep libnotify ];
    text = ''
      cd ${lib.escapeShellArg me.repoPath}

      # Repair links an app replaced with a plain file.
      repaired=0
      while IFS= read -r -d "" f; do
        rel=''${f#${dir}/}
        live="$HOME/.config/$rel"
        if [ -f "$live" ] && [ ! -L "$live" ]; then
          echo "dsync: $live was replaced by its app - copying it into the repo"
          cp -- "$live" "$f"
          rm -- "$live"
          repaired=1
        fi
      done < <(find ${dir} -type f -print0)
      if [ "$repaired" = 1 ]; then
        home-manager switch -b hm-bak --flake . >/dev/null
        echo "dsync: links restored"
      fi

      if [ "$(git branch --show-current)" != main ]; then
        echo "dsync: not on main - skipping" >&2; exit 1
      fi

      git add -A -- ${dir}
      if git diff --cached --quiet -- ${dir}; then
        echo "dsync: nothing changed under ${dir}/"
      else
        # Public repo: refuse anything that looks like a credential.
        if git diff --cached -U0 -- ${dir} | grep -E '^\+' | grep -qiE \
             'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|"?(password|passwd|secret|api[_-]?key|token)"?[[:space:]]*[:=]'; then
          git reset -q -- ${dir}
          notify-send -u critical "Config NOT synced" "A change under ${dir}/ looks like a secret."
          echo "dsync: refused - a change looks like a secret. Review: git diff -- ${dir}" >&2
          exit 1
        fi
        git diff --cached --stat -- ${dir}
        # Pathspec commit: only home/config/, even if other files are staged.
        git commit -q -m "config: sync from $(uname -n)" -- ${dir}
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

  dtrack = pkgs.writeShellApplication {
    name = "dtrack";
    runtimeInputs = with pkgs; [ coreutils git ];
    text = ''
      if [ $# -ne 1 ]; then
        echo "usage: dtrack ~/.config/<app>/<file>" >&2; exit 2
      fi
      src=$(realpath -s -- "$1")
      case "$src" in
        "$HOME/.config/"*) ;;
        *) echo "dtrack: only files under ~/.config are mirrored" >&2; exit 1 ;;
      esac
      [ -f "$src" ] && [ ! -L "$src" ] || { echo "dtrack: $src is not a plain file (already tracked?)" >&2; exit 1; }
      rel=''${src#"$HOME/.config/"}
      dst=${lib.escapeShellArg me.repoPath}/${dir}/$rel
      [ -e "$dst" ] && { echo "dtrack: $dst already exists" >&2; exit 1; }

      mkdir -p -- "$(dirname -- "$dst")"
      mv -- "$src" "$dst"
      cd ${lib.escapeShellArg me.repoPath}
      git add -- "$dst"        # flakes only see files git knows about
      home-manager switch -b hm-bak --flake .
      echo "dtrack: ~/.config/$rel is now tracked as ${dir}/$rel"
    '';
  };
in
{
  xdg.configFile = lib.genAttrs files (f: {
    source = config.lib.file.mkOutOfStoreSymlink "${me.repoPath}/${dir}/${f}";
  });

  home.packages = [ dsync dtrack ];
}
