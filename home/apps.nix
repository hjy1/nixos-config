# My applications and which one opens what.
#
# Every .desktop name below was read out of the package's own
# share/applications/, not guessed - a wrong name here fails silently
# (clicking a file just does nothing).
#
# Settings for Ghostty, niri and DMS are live files in home/config/. VS Code
# and Chrome sync themselves through their own accounts (Settings Sync /
# Chrome Sync), so the repo stays out of their way.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    # VS Code picks its secret store from XDG_CURRENT_DESKTOP, does not know
    # "niri", and falls back to asking for "weaker encryption" - which breaks
    # GitHub sign-in. gnome-keyring is running (programs.niri enables it), so
    # point VS Code at it explicitly.
    (vscode.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    claude-code
    # ghostty is installed by programs.ghostty (home/ghostty.nix)
    nautilus   # files (niri's module provides only its file-picker service)
    loupe      # images
    papers     # PDFs
    mpv
    bilibili
    protonup-qt  # Proton versions for Steam (Steam itself: modules/gaming.nix)
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "application/xhtml+xml" = "google-chrome.desktop";

      # Files
      "inode/directory" = "org.gnome.Nautilus.desktop";

      # Documents
      "application/pdf" = "org.gnome.Papers.desktop";

      # Images
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";

      # Video / audio
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
    };
  };

  home.sessionVariables = {
    BROWSER = "google-chrome-stable";
    TERMINAL = "ghostty";
  };
}
