# General software.
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user.name = "Jiayou He";
      user.email = "forever56946@gmail.com";
    };
  };

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
    # Editors / tooling
    vim
    vscode
    claude-code      # 2.1.327 on unstable, vs 2.1.223 frozen in 26.05
    jq               # was missing; your statusline and plenty else want it
    wget
    curl
    ripgrep
    fd
    tree
    htop
    unzip

    # Terminal
    ghostty

    # Media / entertainment
    bilibili
    mpv
  ];

  # Ghostty is the terminal DMS and niri will spawn by default; nothing to
  # configure here, but note your niri config.kdl decides the keybind.
}
