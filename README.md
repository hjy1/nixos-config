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

### Easy route: graphical installer, then apply this repo

Install a stock system with the graphical ISO, boot in, then:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git
git clone https://github.com/joure5501/nixos-config ~/cfg && cd ~/cfg
mkdir -p hosts/<name>
cp /etc/nixos/hardware-configuration.nix hosts/<name>/
# add a nixosConfigurations.<name> block in flake.nix
git add -A
sudo nixos-rebuild switch --flake .#<name>
```

The installer handles partitioning and your user password. Nothing else needed.

### Declarative route: install from the ISO with `install.sh`

```bash
# 1. get the repo
nix-shell -p git --run 'git clone https://github.com/joure5501/nixos-config /tmp/cfg'

# 2. hardware: partition the disk, probe the machine   [DESTRUCTIVE, once ever]
lsblk                                      # identify the TARGET disk
sudo /tmp/cfg/install.sh prepare laptop /dev/nvme0n1

# 3. software: build and install the configuration     [repeatable, safe]
sudo /tmp/cfg/install.sh apply laptop
```

The split is deliberate. `prepare` is destructive, specific to one physical
machine, and happens exactly once in that machine's life. `apply` is
declarative and re-runnable — it is the same operation `nixos-rebuild switch`
performs for the rest of the machine's life.

Between the two, review what `prepare` generated:

| File | Edit it to |
|---|---|
| `hosts/<name>/default.nix` | pick which modules this machine gets |
| `hosts/<name>/hardware-configuration.nix` | usually leave alone |
| `hosts/<name>/disk.nix` | already points at your disk |

`modules/nvidia.nix` is commented out in the template — it drags in a
multi-GB CUDA closure. Uncomment only on a machine with an NVIDIA GPU.

If you reboot the ISO mid-install, `/mnt` is no longer mounted. Remount
without destroying anything:

```bash
sudo /tmp/cfg/install.sh mount laptop
```

`install.sh --help` prints all of this.

### PASSWORDS - do not skip this

`nixos-install` sets a password for **root only**. The user `he` is declared with
no password, and in NixOS that means login is *disabled*, not blank. You will
reach GDM and find no password works for `he`.

Set it before rebooting, while still in the installer:

```bash
sudo nixos-enter --root /mnt -c 'passwd he'
```

Already rebooted? At the GDM screen hit Ctrl+Alt+F2, log in as `root` with the
install password, run `passwd he`, then Ctrl+Alt+F1.

`users.mutableUsers` is `true` here, so a password set with `passwd` persists
across rebuilds. Never set `mutableUsers = false` without also setting
`users.users.he.hashedPassword`, or every rebuild will lock you out.

`configuration.nix` is written to be host-agnostic; keep it that way. Per-machine
things belong in `hosts/<name>/`.

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
