# The user account. Identity comes from ../me.nix (the `me` argument).
#
# Everything that is about the user rather than the machine - shell plugins,
# prompt, git identity, apps, dotfiles - is NOT here: it lives in home/ and
# is applied by standalone home-manager (`hms`, no sudo). This module only
# makes the account exist.
{ me, ... }:

{
  users.users.${me.name} = {
    isNormalUser = true;
    description = me.fullName;
    extraGroups = [ "networkmanager" "wheel" ];
    # The login shell (zsh) is set in modules/shell.nix.
  };
}
