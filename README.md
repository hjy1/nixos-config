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
| `me.nix` | **Who this is for** — name, email, GitHub account. The only file with personal identity; everything else derives from it |
| `flake.nix` | Inputs, the shared module list, and host auto-discovery |
| `flake.lock` | Exact commit pins — **commit this** |
| `configuration.nix` | Portable base system: boot, locale, audio |
| `modules/user.nix` | The account, `my.repo.*` options, and the home-manager hook |
| `modules/maintenance.nix` | GC, boot-entry cap, fstrim, btrfs scrub |
| `modules/desktop.nix` | niri + Dux Shell, GNOME fallback |
| `modules/shell.nix` | zsh as the login shell — nothing else |
| `modules/packages.nix` | Base admin tools, system git/neovim, nix-ld |
| `modules/fonts.nix` | Font packages and the fallback chain |
| `modules/nvidia.nix` | RTX drivers — `my.nvidia.enable` |
| `modules/gaming.nix` | Steam, gamemode — `my.gaming.enable` |
| `hosts/gear/` | This machine: hardware scan, flags, `stateVersion` |
| `hosts/_template/` | Copy this to add a machine (`_` prefix = not a host) |
| `home/` | **Mine** (home-manager): shell plugins, prompt, git identity, apps, default apps, dotfile links, auto-sync |
| `dotfiles/` | mutable, git-tracked config — **never needs a rebuild** |

### System vs mine

Orthogonal to the layers: **`modules/` is the machine, `home/` is me.**
zsh being the login shell is a system fact (`modules/shell.nix`); starship,
autosuggestions, fzf-tab, fzf, zoxide and direnv are my preferences and live
in `home/shell.nix`. A second user on this machine gets a working zsh and
none of my setup. Rule of thumb: if root or another user needs it, it's
`modules/`; if it's about how *I* like to work, it's `home/`.

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
- GC policy, firewall
- *(in `home/`)* my packages, shell plugins, git identity, default apps

### Tier 2 — `dotfiles/`, mutable, git-tracked, auto-synced (no rebuild)

Cosmetic, tweaked on a whim, wants instant feedback. `home/dotfiles.nix`
links each file into `~/.config` with `mkOutOfStoreSymlink`, which points at
the live checkout rather than a read-only store copy: the *links* are
declarative, the *contents* stay editable.

| File | Controls | Takes effect |
|---|---|---|
| `dotfiles/starship.toml` | prompt | next prompt |
| `dotfiles/zsh/local.zsh` | aliases, fzf-tab previews, colours | new shell / `exec zsh` |
| `dotfiles/niri/config.kdl` | keybinds, column widths, cursor | **instantly** (niri live-reloads) |
| `dotfiles/ghostty/config` | terminal font, theme | on save |
| `dotfiles/dms/settings.json` | everything in DMS Settings (`Mod+,`) | DMS writes it itself |
| `dotfiles/vscode/` | VS Code settings, keybindings, extension list | VS Code writes it itself |

The last two are written *by the apps*. DMS and VS Code write through the
link, so clicking a setting is a repo change — verified for DMS.

**Auto-sync.** A user timer (`dotfiles-sync`, every 10 min; `dsync` to run it
now) commits whatever changed under `dotfiles/` and pushes to GitHub. It only
ever touches `dotfiles/` — Nix changes get a deliberate, hand-written commit.
It refuses to publish anything that looks like a credential and notifies you
instead, and rebases if another machine pushed first. `vscode/extensions.txt`
is refreshed from `code --list-extensions` on every run; on a new machine a
login service installs everything listed.

### Tier 3 — not in this repo at all

**Apps whose "config" is really a database:**

- **Chrome** — the profile is SQLite databases, caches and encrypted
  cookies/passwords, rewritten constantly. Use Chrome Sync (Google account).
- GNOME dconf settings (fallback session only)
- DMS-generated files: `~/.config/niri/dms/*.kdl`, the `dankcolors` Ghostty
  theme. Derived from `dms/settings.json` on every start, so tracking them
  would only record noise.

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
not a Nix quirk. home-manager is wired in as a NixOS module, so adding a
*user* package or plugin also goes through `nrs`. Tier 2 never does: the
links point at the live repo, and the apps reload the files themselves.

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

The `dotfiles/` links are created by home-manager during the switch — no
manual `ln -sf`. If the repo is not at `my.repo.path` yet (a fresh install
that never cloned it), the `nixos-config-clone` user service clones it on
first login and the links start resolving. Verify with:

```bash
ls -l ~/.config/niri/config.kdl ~/.config/dms/settings.json
systemctl --user status dotfiles-sync.timer
```

A file that was already in a link's place is moved aside to `<file>.hm-bak`,
never overwritten.

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

# Clone to my.repo.path (default ~/nixos-config, set in modules/user.nix):
# every dotfile link points there. Skip this and the first login clones it.
git clone https://github.com/hjy1/nixos-config ~/nixos-config && cd ~/nixos-config

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
