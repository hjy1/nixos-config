# System-wide software: what an administrator (or root, or a second user)
# needs on this machine regardless of who logs in. My own applications live
# in home/apps.nix; my git identity in home/git.nix.
{ config, pkgs, ... }:

{
  # git system-wide: the flake, root and nixos-rebuild need it. WHO commits
  # is per-user (home/git.nix).
  programs.git.enable = true;

  # GitHub's SSH host key, so the first `git push` over SSH on a fresh
  # machine doesn't die with "Host key verification failed" (a
  # non-interactive push can't answer the trust-this-host prompt). Verified
  # 2026-11-20 against `gh api meta` and the live server:
  #   SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # System editor: what sudoedit, git-as-root and a rescue shell get.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # NixOS has no /lib, so prebuilt binaries that expect a normal FHS layout
  # fail with cryptic loader errors. nix-ld provides a shim. In practice this
  # is what makes VSCode extensions, bundled language servers, and pip wheels
  # work instead of silently dying.
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    # Base admin tools - things you want in a root shell or over SSH.
    # No `vim`: programs.neovim's vimAlias already provides it, and a real
    # vim here would collide in system-path.
    jq
    wget
    curl
    tree
    htop
    unzip
  ];
}
