# My applications and which one opens what.
#
# Every .desktop name below was read out of the package's own
# share/applications/, not guessed - a wrong name here fails silently
# (clicking a file just does nothing).
#
# App SETTINGS are not here. Those that keep plain config files (VS Code,
# DMS) are linked into dotfiles/ by home/dotfiles.nix; Chrome syncs through
# its own Google account (its profile is databases, not config).
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    vscode
    claude-code
    ghostty
    loupe      # images
    papers     # PDFs
    mpv
    bilibili
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

      # Files (nautilus comes with programs.niri, for the file chooser)
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
