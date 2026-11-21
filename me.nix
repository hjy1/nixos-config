# Who this config belongs to. The ONLY file with personal identity in it.
#
# flake.nix hands this to both halves as the `me` argument:
#   - NixOS (modules/): the user account, the Tailscale operator, groups
#   - home-manager (home/): git identity, the repo path dotfile links use
# Forking this repo for someone else means editing this file, not grepping
# for "he".
rec {
  name = "he";
  fullName = "Jiayou He";
  email = "forever56946@gmail.com";
  github = "hjy1";

  # Where the repo is checked out. Every dotfile link points here.
  repoPath = "/home/${name}/nixos-config";
}
