# niri's config. home-manager has no niri module, so the file itself lives at
# home/niri/config.kdl and home-manager installs it - the standard way to
# manage an app without a module.
#
# Validated at build time: a config niri would reject fails `hms` instead of
# breaking the session. (The DMS includes are `optional=true`, so they do not
# need to exist inside the build sandbox.)
{ pkgs, ... }:

{
  xdg.configFile."niri/config.kdl".source =
    pkgs.runCommand "niri-config.kdl" { nativeBuildInputs = [ pkgs.niri ]; } ''
      cp ${./niri/config.kdl} config.kdl
      niri validate -c config.kdl
      cp config.kdl $out
    '';
}
