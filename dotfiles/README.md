# dotfiles/ — mutable, not declarative

**Nothing in this directory is managed by Nix.**

These are plain files. `modules/shell.nix` only creates *symlinks* from
`~/.config/*` to here; it never reads or generates the contents.

| Edit this | Effect |
|---|---|
| anything in `dotfiles/` | immediate — the app reloads it |
| anything in `modules/` or `configuration.nix` | needs `sudo nixos-rebuild switch` |

So: **no sudo, no rebuild, no waiting.** Change it, save it, done. git still
tracks the change, so it survives and ports to a new machine.

## What goes here

Cosmetics and anything mood-driven: prompt, aliases, keybinds, colours,
fonts choices, padding, themes.

## What does NOT go here

- **Packages** — a font/tool must be *installed* by `modules/`, it cannot be
  conjured from a config file.
- **Assets** — wallpapers and other binaries. Git history is permanent; keep
  them in `~/Pictures/` and point apps at the path.
- **App-managed config** — DMS theming, GNOME dconf, VSCode `settings.json`,
  Chrome profile. Those apps rewrite their own config; let them.
- **Secrets** — tokens, private keys. This repo is meant to be shareable.

## Current files

| File | Linked to | Reloads |
|---|---|---|
| `starship.toml` | `~/.config/starship.toml` | next prompt |
| `zsh/local.zsh` | `~/.config/zsh/local.zsh` | new shell / `exec zsh` |
| `niri/config.kdl` | `~/.config/niri/config.kdl` | instantly |
| `ghostty/config` | `~/.config/ghostty/config` | on save |
