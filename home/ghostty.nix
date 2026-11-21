# Ghostty. Change a value, then `hms` (no sudo); open a new window or press
# Ctrl+Shift+, to reload. home-manager runs `ghostty +validate-config` on
# every switch, so a typo fails `hms` instead of popping an error dialog.
{ ... }:

{
  programs.ghostty = {
    enable = true;
    # Left at the module default (on): Ghostty runs as a systemd user service,
    # upstream's recommended Linux setup - new windows open instantly.
    # systemd.enable = false;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;

      # Built-in names are exact and case-sensitive: `ghostty +list-themes`.
      # "dankcolors" follows the DMS wallpaper palette instead.
      theme = "Catppuccin Mocha";

      background-opacity = 0.95;
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = "none";

      cursor-style = "block";
      mouse-hide-while-typing = true;

      scrollback-limit = 10000;
      copy-on-select = "clipboard";

      # niri handles window management; don't confirm on close.
      confirm-close-surface = false;
    };
  };
}
