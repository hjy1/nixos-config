# The user account. Identity comes from ../me.nix (the `me` argument).
#
# Everything that is about the user rather than the machine - shell plugins,
# prompt, git identity, apps, dotfiles - is NOT here: it lives in home/ and
# is applied by standalone home-manager (`hms`, no sudo). This module only
# makes the account exist.
{ me, pkgs, ... }:

{
  users.users.${me.name} = {
    isNormalUser = true;
    description = me.fullName;
    extraGroups = [ "networkmanager" "wheel" ];
    # The login shell (zsh) is set in modules/shell.nix.

    # TRANSITIONAL (2026-11-20) - delete after the next reboot.
    # Shells opened before the move to standalone home-manager baked
    # /etc/profiles/per-user/<user>/bin/starship into their prompt; that path
    # vanished with the NixOS module and they print "no such file" at every
    # prompt. This puts starship back at the old path so those shells keep
    # working without being reopened. New shells use ~/.nix-profile, which
    # survives every `hms`, so this can never be needed again.
    packages = [ pkgs.starship ];
  };
}
