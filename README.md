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
| `modules/user.nix` | The user account (identity from `me.nix`) |
| `modules/maintenance.nix` | GC, boot-entry cap, fstrim, btrfs scrub |
| `modules/desktop.nix` | niri + Dux Shell, the DMS login screen, the services DMS needs |
| `modules/shell.nix` | zsh as the login shell — nothing else |
| `modules/packages.nix` | Base admin tools, system git/neovim, nix-ld |
| `modules/fonts.nix` | Font packages and the fallback chain |
| `modules/nvidia.nix` | RTX drivers — `my.nvidia.enable` |
| `modules/gaming.nix` | Steam, gamemode — `my.gaming.enable` |
| `modules/tailscale.nix` | Tailscale client — `my.tailscale.enable`; once: `sudo tailscale up` |
| `hosts/gear/` | This machine: hardware scan, flags, `stateVersion` |
| `hosts/_template/` | Copy this to add a machine (`_` prefix = not a host) |
| `home/` | **Mine** — standalone home-manager, `hms` with **no sudo**: apps, zsh plugins, git, default apps |
| `home/config/` | My config files, mirroring `~/.config` and linked live — edit them normally |

### The machine vs me — and the sudo rule

Two halves, two commands:

| | Where | Applied by | sudo |
|---|---|---|---|
| **the machine** | `configuration.nix`, `modules/`, `hosts/` | `nrs` — `sudo nixos-rebuild switch` | yes |
| **me** | `home/` (home-manager, standalone) | `hms` — `home-manager switch` | **no** |

**The rule, borrowed from Arch:** if on Arch it would need `sudo pacman` or
`sudo systemctl enable`, it belongs to the machine and `sudo` is fine. If on
Arch you would just edit a file in your home directory, it must never need
`sudo` here — so it lives in `home/`.

So zsh *as the login shell* is the machine (`modules/shell.nix`), but
starship, autosuggestions, fzf-tab, fzf, zoxide and direnv are me
(`home/shell.nix`). A second user gets a working zsh and none of my setup.

home-manager runs **standalone**, not as a NixOS module, precisely for the
sudo rule: as a module every user-level change would go through
`sudo nixos-rebuild`. `me.nix` is passed to both halves as `me`, so identity
is still defined once.

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

## How a change is made

home-manager owns everything of mine, in two forms:

- **`home/*.nix`** — what is installed and wired up: my apps, zsh plugins,
  git identity, default apps. Change it, then `hms` (no sudo).
- **`home/config/`** — my config files. It mirrors `~/.config`, and every
  file in it is linked **live**: `~/.config/ghostty/config` *is*
  `home/config/ghostty/config`. Edit it the normal way, at either path, in
  any editor — it applies like on any other distro, and `git diff` already
  shows the change. No command.

| To change… | Edit | Then |
|---|---|---|
| Ghostty font, theme | `~/.config/ghostty/config` | Ctrl+Shift+, in Ghostty |
| prompt | `~/.config/starship.toml` | nothing (next prompt) |
| aliases, fzf-tab previews | `~/.config/zsh/local.zsh` | `exec zsh` |
| niri keybinds, layout | `~/.config/niri/config.kdl` | nothing (niri reloads) |
| DMS: wallpaper, bar, gaps, monitors | DMS Settings (`Mod+,`) | nothing — DMS saves through the link |
| zsh plugins, history | `home/shell.nix` | `hms` |
| git identity, gh | `home/git.nix` (name/email from `me.nix`) | `hms` |
| my apps, default apps | `home/apps.nix` | `hms` |
| drivers, services, desktop, fonts, Tailscale | `modules/`, `hosts/` | `nrs` (sudo) |

### A new app's config

home-manager does not capture anything by itself — it manages exactly the
files it is told about. To track one, move it into the mirror and switch:

```bash
mkdir -p ~/nixos-config/home/config/<app>
mv ~/.config/<app>/<file> ~/nixos-config/home/config/<app>/
cd ~/nixos-config && git add home/config/<app> && hms
```

`hms` puts a link where the file was; from then on it is edited normally.
(`git add` is needed because flakes only see files git knows about.)
Toolchains like JDKs or Rust are *tools*, not config: install them in
`home/apps.nix`, or per project with a devShell + direnv.

### Publishing

Plain git — the repo is the source of truth:

```bash
cd ~/nixos-config && git diff        # what changed (the repo is public: look)
git commit -am "..." && git push
```

One thing to know: some apps save by *replacing* their file (write a temp
file, rename it over the original). That turns the link into a plain file,
and the repo stops seeing changes. `ls -l ~/.config/<app>/<file>` shows
which it is; to fix, copy the file over the one in `home/config/`, delete
it from `~/.config`, and `hms`.

DMS *generates* `~/.config/niri/dms/*.kdl` and a `dankcolors` Ghostty theme
from its settings on every start. They are derived, so they are not tracked;
`niri/config.kdl` pulls them in with `include optional=true`.

### Not in this repo at all

**Apps that sync themselves:**

- **Chrome** — the profile is SQLite databases, caches and encrypted
  cookies/passwords, rewritten constantly. Use Chrome Sync (Google account).
- **VS Code** — settings, keybindings and extensions sync through VS Code's
  own Settings Sync (sign in with GitHub). Tracking them here too would put
  two syncs on the same files. The flake only installs VS Code and points it
  at gnome-keyring so that sign-in works under niri.

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

The same split applies to themes: **installing** an icon theme, cursor theme
or font is the machine (`modules/fonts.nix`, `nrs`); **choosing** which one
Ghostty or niri uses is mine (`home/config/`, no command).

## Applying

**Bootstrap note.** Flakes are gated behind an experimental flag that is *not*
set on a stock NixOS install, and `nixos-rebuild --flake` needs it.
`configuration.nix` enables it permanently — but that only takes effect *after*
the first successful build, so the first two commands have to pass it by hand.
Chicken-and-egg; it bites everyone once.

```bash
# 1. Build without activating — catches problems before anything changes
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

The login screen is DMS's own greeter (it copies your DMS wallpaper and
theme), and **niri** is the session.

**Changing the login manager** (as the GNOME → DMS-greeter move did) must be
applied with `sudo nixos-rebuild boot --flake ~/nixos-config` and a reboot,
not `switch`: a live switch stops the old login manager, and with it the
session you are running the command from.

Then apply **me** — once, as your user, no sudo. The first time the
`home-manager` command does not exist yet, so run it from the flake input;
it installs itself, and from then on it is just `hms`:

```bash
nix run home-manager -- switch -b hm-bak --flake ~/nixos-config
exec zsh          # pick up the new shell config
```

That writes every config file of mine — no manual `ln -sf`. A file already
in the way is moved aside to `<file>.hm-bak`, never overwritten. Verify:

```bash
ls -l ~/.config/niri/config.kdl ~/.config/dms/settings.json
```

**Then the sign-ins** — state no config can (or should) contain:

```bash
gh auth login            # GitHub, then SSH key upload when asked
sudo tailscale up        # opens a login URL
```

Chrome and VS Code: sign in inside the apps; their own sync restores
bookmarks, extensions and settings.

## If niri doesn't come up

There is no GNOME fallback session any more. Switch to a text console with
**Ctrl+Alt+F3**, log in, then:

```bash
systemctl --user status dms          # is Dux Shell running?
journalctl --user -u dms -b          # why not
dms doctor                           # DMS's own dependency check
niri msg outputs                     # real monitor names for config.kdl
```

Worst case, pick the previous generation in systemd-boot at power-on — it
still has GNOME if you need a full desktop to fix things. Nothing here is
one-way.

## Adding a second machine

### Easy route: graphical installer, then apply this repo

Install a stock system with the graphical ISO, boot in, then:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git

# Clone to repoPath from me.nix (default ~/nixos-config): every dotfile
# link points there.
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

# Then "me", as your user - no sudo (see Applying above):
nix run home-manager -- switch -b hm-bak --flake ~/nixos-config
```

The installer handles partitioning and your user password. After that, only
the sign-ins in "Applying" remain.

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
password in `configuration.nix`, so without one of the fixes below you reach the login screen
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
