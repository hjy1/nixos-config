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
$EDITOR hosts/laptop/default.nix    # pick modules (nvidia is off by default)
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

`modules/nvidia.nix` is commented out in the template — it drags in a multi-GB
CUDA closure. Uncomment only on a machine with an NVIDIA GPU.

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
