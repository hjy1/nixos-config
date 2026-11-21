# My git identity and GitHub tooling. git itself is installed system-wide
# (modules/packages.nix) - root and the flake need it - but who I am is mine.
{ me, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = me.fullName;
      user.email = me.email;
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.gh = {
    enable = true;
    # git asks gh for GitHub HTTPS credentials, so `gh auth login` once is
    # all a fresh machine needs. SSH pushes use ~/.ssh as usual.
    gitCredentialHelper.enable = true;
    settings.git_protocol = "ssh";
  };

  # gh runs the browser command and WAITS for it to exit; if Chrome was not
  # already open it becomes gh's child and `gh auth login` hangs after GitHub
  # says "you're all set". `gio open` hands the URL off and returns at once.
  home.sessionVariables.GH_BROWSER = "${pkgs.glib.bin}/bin/gio open";
}
