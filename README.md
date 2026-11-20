# nixos-config — MAINGEAR MG-1 MK.II

Flake-based NixOS config. Tracks `nixos-unstable`; `flake.lock` pins the exact
nixpkgs commit so this reproduces identically on any machine.

## Layout

| Path | Purpose |
|---|---|
| `flake.nix` | Inputs (nixpkgs-unstable) and the `mg1` host output |
| `flake.lock` | Exact commit pins — **commit this** |
| `configuration.nix` | Portable base system |
| `hosts/mg1/hardware-configuration.nix` | Machine-specific. Regenerate per machine. |
| `modules/nvidia.nix` | RTX 50-series drivers + CUDA |
| `modules/desktop.nix` | niri + Dux Shell, GNOME fallback |
| `modules/packages.nix` | General software |
| `modules/gaming.nix` | Steam, gamemode |
| `dotfiles/niri/config.kdl` | niri config (symlink into `~/.config/niri/`) |

## Applying

**Bootstrap note.** Flakes are gated behind an experimental flag that is *not*
set on a stock NixOS install, and `nixos-rebuild --flake` needs it.
`configuration.nix` enables it permanently — but that only takes effect *after*
the first successful build, so the first two commands have to pass it by hand.
Chicken-and-egg; it bites everyone once.

```bash
# 1. Build without activating — catches problems while GNOME still works
sudo nixos-rebuild build --flake ~/nixos-config#mg1 \
  --option extra-experimental-features "nix-command flakes"

# 2. Activate
sudo nixos-rebuild switch --flake ~/nixos-config#mg1 \
  --option extra-experimental-features "nix-command flakes"

# 3. Reboot (required: the NVIDIA kernel module swap won't take live)
sudo reboot
```

Every rebuild after that needs no flag, because the built system now sets it:

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#mg1
```

At the GDM login screen pick **niri** (it's the default) or **GNOME** (fallback).

Link the niri config in before your first niri login:

```bash
mkdir -p ~/.config/niri
ln -sf ~/nixos-config/dotfiles/niri/config.kdl ~/.config/niri/config.kdl
```

## If niri doesn't come up

Pick GNOME at the login screen, then:

```bash
systemctl --user status dms          # is Dux Shell running?
journalctl --user -u dms -b          # why not
dms doctor                           # DMS's own dependency check
niri msg outputs                     # real monitor names for config.kdl
```

Worst case, pick the previous generation in systemd-boot at power-on. Nothing
here is one-way.

## Adding a second machine

```bash
sudo nixos-generate-config --dir /tmp/hw
mkdir -p hosts/<name>
cp /tmp/hw/hardware-configuration.nix hosts/<name>/
```

Then add a `nixosConfigurations.<name>` block in `flake.nix` reusing the same
`configuration.nix` and whichever modules apply. `configuration.nix` is written
to be host-agnostic; keep it that way.

## Updating

```bash
nix flake update                                      # move nixpkgs forward
sudo nixos-rebuild switch --flake ~/nixos-config#mg1
```

Because `flake.lock` is committed, `git log flake.lock` is a full history of
every package-set bump, and `git revert` undoes a bad one.

## Known-unverified bits

- The `dms ipc call <target> <function>` **syntax** is confirmed, but the target
  names in `config.kdl` (`spotlight`, `powermenu`, `clipboard`) are not — they
  couldn't be enumerated without DMS running. Run `dms ipc call` with no args,
  or `dms keybinds`, once you're in niri and correct the binds if needed.
- Monitor settings in `config.kdl` are commented out pending real output names
  from `niri msg outputs`.
