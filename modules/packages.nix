# General software.
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user.name = "Jiayou He";
      user.email = "forever56946@gmail.com";
      # git asks gh for GitHub HTTPS credentials, so `gh auth login` once is
      # all a fresh machine needs. Same thing `gh auth setup-git` would write
      # to ~/.gitconfig, but declared - so it survives a reinstall. The
      # empty helper first clears any inherited helper for this host.
      credential."https://github.com".helper = [ "" "!gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
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
    # No `vim` here: programs.neovim above sets vimAlias, and a real vim in
    # this list collides with it in system-path. buildEnv has
    # ignoreCollisions = true, so the loser is dropped with only a warning -
    # and which one wins depends on module order. Leave nvim unopposed.
    # ripgrep and fd live in modules/shell.nix, not duplicated here.
    vscode
    claude-code      # 2.1.327 on unstable, vs 2.1.223 frozen in 26.05
    gh               # GitHub CLI; also git's credential helper (above)
    jq               # was missing; your statusline and plenty else want it
    wget
    curl
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
