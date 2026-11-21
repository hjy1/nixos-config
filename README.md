# nixos-config — MAINGEAR MG-1 MK.II

Flake-based NixOS config. Tracks `nixos-unstable`; `flake.lock` pins the exact
nixpkgs commit so this reproduces identically on any machine.

## Layout

Three layers, and every file belongs to exactly one.

| Layer | Where | Applies to | Rule |
|---|---|---|---|
| **base** | `configuration.nix`, `modules/maintenance.nix` | every host, unconditionally | states its opinions with `lib.mkDefault`, so a host can disagree without `mkForce` |
| **feature** | `modules/*.nix` | imported on every host; acts only if its `my.*` flag is on | one concern per file |
| **host** | `hosts/<name>/` | exactly one machine | hardware, disks, feature flags, `stateVersion` |

| Path | Purpose |
|---|---|
| `flake.nix` | Inputs, the shared module list, and host auto-discovery |
| `flake.lock` | Exact commit pins — **commit this** |
| `configuration.nix` | Portable base system: boot, locale, audio, users |
| `modules/maintenance.nix` | GC, boot-entry cap, fstrim, btrfs scrub |
| `modules/desktop.nix` | niri + Dux Shell, GNOME fallback |
| `modules/shell.nix` | zsh, starship, fzf, direnv, the `dotfiles/` symlinks |
| `modules/packages.nix` | General software |
| `modules/defaults.nix` | Default applications and mime handlers |
| `modules/fonts.nix` | Font packages and the fallback chain |
| `modules/nvidia.nix` | RTX drivers — `my.nvidia.enable` |
| `modules/gaming.nix` | Steam, gamemode — `my.gaming.enable` |
| `hosts/gear/` | This machine: hardware scan, flags, `stateVersion` |
| `hosts/_template/` | Copy this to add a machine (`_` prefix = not a host) |
| `dotfiles/` | mutable, git-tracked config — **never needs a rebuild** |

Two things are deliberately absent from the host layer: the **module list** (it
is identical for every host, in `flake.nix`) and the **hostname** (derived from
the host's directory name). Curating a per-host import list is what let
`hosts/gear` and `hosts/_template` drift into two different systems — one with
zsh and fonts, one without.

### How the layers merge

"Layer" is a filing metaphor, not a Nix mechanism, and the two places it leaks
are worth knowing:

**`imports` is a set, not a stack.** The module system collects every import
into one unordered set and merges them in a fixpoint. Reordering the list in
`flake.nix` produces a bit-identical system; the only thing that shifts is the
order of `environment.systemPackages`, which changes a derivation hash without
changing its contents.

**Conflicts resolve by priority, not by position.** Nothing "wins by being
later". Lower number wins:

| | priority | meaning here |
|---|---|---|
| option's own default | 1500 | what nixpkgs ships |
| `lib.mkDefault` | 1000 | the base layer's opinion |
| plain definition | 100 | a host's decision |
| `lib.mkForce` | 50 | override something already claimed at 100 |

Two *plain* definitions of the same scalar is an eval error, not last-write-
wins — which is the feature. It means a host overriding the base layer either
works or fails loudly; it never silently half-applies.

The corollary, and the one real trap: `mkDefault` is not free insurance. Two
`mkDefault`s with different values are *also* a conflict, because they tie.
`modules/shell.nix` has to define `users.defaultUserShell` plainly for exactly
that reason — nixpkgs' own `bash.nix` already claims it with `mkDefault`, so a
second `mkDefault` there fails to evaluate. The comment in that file explains
it in place.

## What belongs in Nix, and what doesn't

The governing rule: **if you'd change it because of your mood, it does not go
in Nix.** A rebuild is the right price for things that can break the machine.
It is the wrong price for a prompt colour.

Note this is a *different axis* from the three layers above. Layers answer
"which file defines this option"; tiers answer "how expensive is it to change".

### Tier 1 — declarative Nix (rebuild required, and that's correct)

Structural, breaks things if wrong, changes rarely:

- kernel, bootloader, initrd, `configurationLimit`
- NVIDIA driver, filesystems, disk layout
- **which packages exist**
- services: pipewire, gdm, niri, dms, direnv, zram
- users, hostname, networking, locale, timezone
- GC policy, firewall, mime defaults

### Tier 2 — `dotfiles/`, mutable and git-tracked (no rebuild)

Cosmetic, tweaked on a whim, wants instant feedback. Symlinked into
`~/.config` by `systemd.user.tmpfiles` rules in `modules/shell.nix`, so the
*links* are declarative while the *contents* stay editable.

| File | Controls | Takes effect |
|---|---|---|
| `dotfiles/starship.toml` | prompt | next prompt |
| `dotfiles/zsh/local.zsh` | aliases, fzf-tab previews, colours | new shell / `exec zsh` |
| `dotfiles/niri/config.kdl` | keybinds, column widths, cursor | **instantly** (niri live-reloads) |

Edit these directly. `git diff` sees the change; no `nixos-rebuild` involved.

### Tier 3 — not in this repo at all

**Apps that manage their own config.** Declaring these means fighting them
every time they hit "save":

- **DMS / Dux Shell** — theming, wallpaper, bar layout, monitors, gaps. It
  writes `~/.config/dms/` and generates `~/.config/niri/dms/*.kdl`, which
  `config.kdl` pulls in with `include optional=true`. `matugen` derives
  palettes from your wallpaper. Change these in DMS Settings (`Mod+,`), not
  in git.
- GNOME dconf settings
- VSCode `settings.json` and extensions
- Chrome profile, extensions, bookmarks

**Data.** Nix is not a backup system:

- Steam and its games (`~/.local/share/Steam`) — content delivery, not config
- `~/Documents`, photos, model weights, databases
- project `.venv` / `node_modules` — `uv.lock` and `package-lock.json` own those

**Credentials.** Never commit these: `~/.config/gh`, SSH private keys, API
tokens. Use `sops-nix`/`agenix` if a secret must be declared.

**Assets — wallpapers, and anything binary.** Keep these in `~/Pictures/`,
not in this repo and not in the Nix store. Three reasons:

1. Git history is forever. A 10MB wallpaper you delete next week still lives
   in every future clone.
2. Every generation would retain it in the store, and GC holds generations
   for 30 days.
3. Changing your wallpaper would require a rebuild — absurd.

DMS and matugen take a *path*. Point them at `~/Pictures/wallpapers/` and let
them read a plain mutable file.

The same split applies to themes: **the package** (an icon theme, a cursor
theme, a font) is Tier 1 because it must exist to be selectable. **The
selection** is Tier 2 or 3, because it's taste.

`modules/fonts.nix` is the clearest example — which fonts are installed is
declarative; which font Ghostty uses lives in `dotfiles/ghostty/config`.

### A note on sudo

Tier 1 needs `sudo` because it activates a system profile — that's inherent,
not a Nix quirk. Tier 2 never does: the files are yours, and the apps reload
them live. That's the real reason the split matters day to day.

If you want *declarative* user config **without** sudo, that is what
home-manager in **standalone** mode gives you (`home-manager switch`, no
root, rebuilds only your user generation in seconds). Note the trap: wiring
home-manager in as a NixOS module puts it back behind `sudo nixos-rebuild`.
Standalone is the mode that solves this problem; the module is not.

### When unsure

Start in `dotfiles/`. Promote to Nix only once you're sure it must be
identical on every machine. Demotion is easy; discovering you need a rebuild
to change a colour is the annoying direction.

## Applying

**Bootstrap note.** Flakes are gated behind an experimental flag that is *not*
set on a stock NixOS install, and `nixos-rebuild --flake` needs it.
`configuration.nix` enables it permanently — but that only takes effect *after*
the first successful build, so the first two commands have to pass it by hand.
Chicken-and-egg; it bites everyone once.

```bash
# 1. Build without activating — catches problems while GNOME still works
sudo nixos-rebuild build --flake ~/nixos-config#gear \
  --option extra-experimental-features "nix-command flakes"

# 2. Activate
sudo nixos-rebuild switch --flake ~/nixos-config#gear \
  --option extra-experimental-features "nix-command flakes"

# 3. Reboot (required: the NVIDIA kernel module swap won't take live)
sudo reboot
```

Every rebuild after that needs no flag, because the built system now sets it:

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#gear
```

At the GDM login screen pick **niri** (it's the default) or **GNOME** (fallback).

The `dotfiles/` symlinks are created for you by the `systemd.user.tmpfiles`
rules in `modules/shell.nix` — no manual `ln -sf`. They appear on your next
login; verify with:

```bash
ls -l ~/.config/niri/config.kdl ~/.config/starship.toml ~/.config/zsh/local.zsh
```

Each should point into `~/nixos-config/dotfiles/`. If one is missing, force
the rules immediately rather than logging out:

```bash
systemd-tmpfiles --user --create
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

# Clone to ~/nixos-config specifically: the dotfile symlinks in
# modules/shell.nix point at that path and dangle anywhere else.
git clone https://github.com/joure5501/nixos-config ~/nixos-config && cd ~/nixos-config

mkdir -p hosts/<name>
cp /etc/nixos/hardware-configuration.nix hosts/<name>/
cp hosts/_template/default.nix          hosts/<name>/

# A host directory MUST have a default.nix - the flake imports the directory.
# On this route there is no disko, so delete the ./disk.nix import from it,
# then set system.stateVersion and whichever my.* flags apply.
$EDITOR hosts/<name>/default.nix

# Nothing to add to flake.nix: hosts/<name>/ is discovered automatically and
# the directory name becomes the hostname.
git add -A
sudo nixos-rebuild switch --flake .#<name>
```

The installer handles partitioning and your user password. Nothing else needed.

### Declarative route: `nixos-anywhere`

You run this **from this machine**, pushing a system onto the target over SSH.
The target never clones this repo and never needs git — the flake is evaluated
and built here, then the closure is copied across.

**On the target machine:** boot any NixOS ISO, then

```bash
sudo passwd root       # nixos-anywhere needs root SSH access
ip -brief addr         # note the IP
```

**Here:** create the host, two small files.

```bash
mkdir -p hosts/laptop
cp hosts/_template/{default.nix,disk.nix,hardware-configuration.nix} hosts/laptop/
$EDITOR hosts/laptop/disk.nix       # set `device` to the target's disk
$EDITOR hosts/laptop/default.nix    # stateVersion + my.* feature flags
git add -A                          # new files are invisible to the flake until staged
```

Optional but recommended — test the disk layout in a VM, touching no hardware:

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#laptop --vm-test
```

Then install:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#laptop \
  --generate-hardware-config nixos-generate-config ./hosts/laptop/hardware-configuration.nix \
  --target-host root@192.168.1.50
```

`--generate-hardware-config` probes the target and writes the real hardware
scan back into this repo, replacing the placeholder. Commit it afterwards.

Default phases are `kexec,disko,install,reboot` — pass `--phases` to run a
subset. `--build-on remote` builds on the target instead of here, useful if the
target is beefier or you're on a slow uplink.

The `hosts/_template/hardware-configuration.nix` placeholder exists because the
disko phase has to evaluate `nixosConfigurations.laptop` before the target has
been probed. It gets overwritten; don't bother editing it.

`my.nvidia.enable` is off in the template — the driver drags in a multi-GB
closure. Turn it on only on a machine with an NVIDIA GPU.

### PASSWORDS - do not skip this

A user declared with no password has login **disabled**, not blank. `he` has no
password in `configuration.nix`, so without one of the fixes below you reach GDM
and find that nothing works.

**With the graphical installer** this is handled — it asks you for a user
password during setup.

**With nixos-anywhere it is not.** The install is fully non-interactive: nothing
prompts, and root gets no password either. Decide before you install:

*Option A - declare a hash (simplest).* Generate one and put it in
`hosts/<name>/default.nix`:

```bash
mkpasswd -m yescrypt          # paste the output below
```

```nix
users.users.he.initialHashedPassword = "$y$j9T$...";
```

A yescrypt hash is not plaintext, but on a **public** repo it is still offline-
crackable. Use a throwaway, change it on first login, and move real secrets to
`sops-nix`/`agenix` later.

*Option B - SSH key instead.* Declare your public key and log in over SSH,
then `passwd` yourself:

```nix
users.users.he.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
services.openssh.enable = true;
```

*Recovering a machine you already locked yourself out of:* boot it, press
Ctrl+Alt+F2 at the login screen, and if root has no password either, reboot
picking an older generation or re-run the install with Option A in place.

`users.mutableUsers` is `true` here, so a password set with `passwd` persists
across rebuilds, and `initialHashedPassword` applies only on first activation.
Never set `mutableUsers = false` without also setting `hashedPassword`, or every
rebuild will lock you out.

`configuration.nix` is written to be host-agnostic; keep it that way. Per-machine
things belong in `hosts/<name>/`.

## Updating

```bash
nix flake update                                      # move nixpkgs forward
sudo nixos-rebuild switch --flake ~/nixos-config#gear
```

Because `flake.lock` is committed, `git log flake.lock` is a full history of
every package-set bump, and `git revert` undoes a bad one.

## Known-unverified bits

- Monitor DDC brightness: the user is in `i2c` and the module enables
  `hardware.i2c`, but whether the LG UltraFine answers DDC/CI is a property of
  the monitor. `dms doctor` reports "I2C/DDC" once it can see one.
