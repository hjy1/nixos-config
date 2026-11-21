# My config files, edited NORMALLY and captured in the repo.
#
# home/config/ mirrors ~/.config. For every file in it, home-manager makes
#   ~/.config/<path>  ->  <repo>/home/config/<path>
# a link to the LIVE file in this checkout (mkOutOfStoreSymlink), not a
# read-only copy. Edit ~/.config/ghostty/config the normal way - or let an
# app's own settings UI write it (DMS) - and the change is already in the
# repo. Nothing to list here: the directory is the list.
#
# Tracking a new app's config (see README):
#   mv ~/.config/<app>/<file> ~/nixos-config/home/config/<app>/<file>
#   git add home/config/<app>/<file> && hms
{ config, me, lib, ... }:

let
  # Every file under ./config, as a path relative to it.
  walk = path: prefix:
    lib.concatLists (lib.mapAttrsToList
      (name: type:
        if type == "directory"
        then walk (path + "/${name}") "${prefix}${name}/"
        else [ "${prefix}${name}" ])
      (builtins.readDir path));
in
{
  xdg.configFile = lib.genAttrs (walk ./config "") (f: {
    source = config.lib.file.mkOutOfStoreSymlink "${me.repoPath}/home/config/${f}";
  });
}
