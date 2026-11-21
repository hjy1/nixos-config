# Ghostty: installed and run as a systemd user service by home-manager
# (upstream's recommended Linux setup - new windows open instantly).
#
# Its settings are NOT here: they are the live file home/config/ghostty/config
# (= ~/.config/ghostty/config), edited normally. With `settings` left empty
# this module writes no config file, so it never collides with that link.
{ ... }:

{
  programs.ghostty.enable = true;
}
