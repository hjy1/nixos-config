# My applications and which one opens what.
#
# Every .desktop name below was read out of the package's own
# share/applications/, not guessed - a wrong name here fails silently
# (clicking a file just does nothing).
#
# App SETTINGS are not here. DMS's are linked into dotfiles/ by
# home/dotfiles.nix. VS Code and Chrome sync themselves through their own
# accounts (Settings Sync / Chrome Sync), so the repo stays out of their way.
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
