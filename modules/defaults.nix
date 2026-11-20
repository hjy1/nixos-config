# Default applications and the viewers they point at.
#
# Every .desktop name below was read out of the package's own
# share/applications/, not guessed - a wrong name here fails silently
# (clicking a file just does nothing).
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome   # unfree; covered by nixpkgs.config.allowUnfree
    loupe           # images   -> org.gnome.Loupe.desktop
    papers          # PDFs     -> org.gnome.Papers.desktop
    # nautilus comes in via programs.niri (useNautilus, for the file chooser)
  ];

  xdg.mime.defaultApplications = {
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

  environment.sessionVariables = {
    BROWSER = "google-chrome-stable";
    TERMINAL = "ghostty";
    # EDITOR is already set to nvim by programs.neovim.defaultEditor
  };
}
