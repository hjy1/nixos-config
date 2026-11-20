# General software.
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      # Set these yourself:
      # user.name = "Jiayou He";
      # user.email = "you@example.com";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

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
