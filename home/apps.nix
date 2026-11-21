# My applications and which one opens what.
#
# Every .desktop name below was read out of the package's own
# share/applications/, not guessed - a wrong name here fails silently
# (clicking a file just does nothing).
#
# Settings for Ghostty, niri, DMS and VSCodium are live files in home/config/.
# Chrome syncs itself through its own account (Chrome Sync), so the repo stays
# out of its way.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    # VSCodium: VS Code built from the MIT source, without Microsoft's
    # license, telemetry or Marketplace. Extensions come from Open VSX,
    # installed inside the editor (they auto-update; nixpkgs' copies lag).
    # Settings: home/config/VSCodium/User/.
    #
    # It picks its secret store from XDG_CURRENT_DESKTOP, does not know
    # "niri", and falls back to asking for "weaker encryption" - which breaks
    # extension sign-ins. gnome-keyring is running (programs.niri enables
    # it), so point it there explicitly.
    (vscodium.override { commandLineArgs = "--password-store=gnome-libsecret"; })
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
