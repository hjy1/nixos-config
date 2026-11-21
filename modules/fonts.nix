# Fonts.
#
# This module is a clean illustration of the machine / me split:
#
#   WHICH FONTS EXIST          -> here. A font that isn't installed cannot be
#                                 selected, and missing glyphs are a broken
#                                 system, not a style preference.
#   WHICH FONT A THING USES    -> home/ (`hms`, no sudo). Terminal font and
#                                 size are taste; see home/ghostty.nix.
{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      # Nerd Font: starship's ❄/❯ and the whole DMS icon set are glyphs from
      # this. Without it they render as tofu boxes - which looks like a
      # broken desktop, not a cosmetic choice.
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only

      # Broad Unicode coverage, CJK, and emoji.
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    enableDefaultPackages = true;

    # System-wide fallback chain. Structural rather than cosmetic: this is
    # what renders when an application asks for a generic family. Individual
    # apps still override it in their own config.
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC" ];
      sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
      serif = [ "Noto Serif" "Noto Serif CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
