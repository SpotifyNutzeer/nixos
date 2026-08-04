# Design: Host profile `laptop` (Lenovo IdeaPad, 10.0.1.46)

**Date:** 2026-07-04
**Status:** Implemented (status updated 2026-08-03)

## Goal

A new NixOS host profile `laptop` for the Lenovo laptop (currently Fedora 42,
reachable via SSH at `paul@10.0.1.46`), installed via **nixos-anywhere**
over SSH. The laptop gets the same graphical setup as the desktop
(SDDM + Hyprland + Catppuccin), extended with laptop specifics.

## Hardware (determined via SSH)

| Component | Value |
|---|---|
| Device | Lenovo 82X3 (IdeaPad) |
| CPU/GPU | AMD Ryzen 5 7540U with Radeon 740M (integrated, Phoenix) |
| RAM | 16 GB |
| Disk | 1 TB NVMe (`/dev/nvme0n1`) |
| Display | eDP-1, 1920x1200 native |
| WLAN | Realtek RTL8852CE (kernel support available) |
| Firmware | UEFI |

## Decisions

1. **Installation:** nixos-anywhere (remote over SSH, wipes the disk completely —
   Fedora and `/home` are lost; back up data beforehand).
2. **Encryption:** LUKS full-disk encryption, one passphrase at boot.
3. **Graphical setup:** same as desktop — SDDM becomes a shared module.
4. **Swap:** 20 GB swap partition **inside** LUKS, hibernate-capable.
5. **Hostname:** `paul-laptop`.

## Architecture

### 1. Flake changes (`flake.nix`)

- New input `disko` (`github:nix-community/disko`, `inputs.nixpkgs.follows = "nixpkgs"`).
- `disko.nixosModules.disko` into the `mkHost` module list (harmless for `desktop`/`vm`,
  which do not configure any `disko.*`).
- `nixosConfigurations.laptop = mkHost "laptop"`.

### 2. Disk layout (`hosts/laptop/disko.nix`)

GPT on `/dev/nvme0n1`:

- **ESP:** 1 GB, vfat, mounted as `/boot`.
- **LUKS container `cryptroot`** (rest of the disk), containing LVM (VG `vg0`):
  - **LV `swap`:** 20 GB swap (so the hibernate image is stored encrypted).
  - **LV `root`:** rest, btrfs with subvolumes `/root` (→ `/`), `/home`, `/nix`,
    each with `compress=zstd`, `/nix` additionally `noatime`.

One passphrase unlocks the container; swap and root hang off the same LUKS.

### 3. Host profile (`hosts/laptop/`)

- **`default.nix`** — imports `../../common`, `../../common/sddm.nix`,
  `./hardware-configuration.nix`, `./disko.nix`, `./boot.nix`, `./power.nix`;
  injects `./hyprland-monitors.nix` via `home-manager.users.paul.imports`;
  `networking.hostName = "paul-laptop"`; `system.stateVersion = "26.05"`.
- **`boot.nix`** — systemd-boot, `configurationLimit`, zen kernel (same as desktop);
  **`boot.initrd.systemd.enable = true`** (see keyboard layout);
  `boot.resumeDevice` set to the swap LV (`/dev/vg0/swap`) for hibernate.
- **`hardware-configuration.nix`** — generated during installation by nixos-anywhere
  (`--generate-hardware-config`) and overwritten in the process; until then a
  placeholder with `nixpkgs.hostPlatform = "x86_64-linux"`. That is why
  `hardware.cpu.amd.updateMicrocode = true` and
  `hardware.enableRedistributableFirmware = true` (WLAN firmware) live
  permanently in `boot.nix`, not here.
- **`power.nix`** — `services.tlp.enable = true` (battery life),
  `brightnessctl` as a system package (the brightness keys are already bound
  in the Hyprland config), `services.logind` defaults for lid-close → suspend.
  The AMD GPU needs no extra configuration (Mesa is the default).
- **`hyprland-monitors.nix`** — home-manager module:
  `monitorv2 = [{ output = "eDP-1"; mode = "1920x1200@60"; position = "0x0"; scale = "1.0"; }]`.

### 4. SDDM becomes a shared module

- `hosts/desktop/sddm.nix` → **`common/sddm.nix`** (content unchanged,
  incl. Catppuccin and gnome-keyring).
- Deliberately **not** added to `common/default.nix` — otherwise the VM would
  get a login manager. Desktop and laptop import it explicitly.

### 5. Hyprland monitors per host

The `monitorv2` entries (HDMI-A-1, DP-2, DP-3) and the workspace bindings
(`1, monitor:HDMI-A-1` etc.) are desktop-specific but live in the shared
`home/program-configs/hyprland.nix`. They move into
**`hosts/desktop/hyprland-monitors.nix`** (HM module, injected via the
existing `home-manager.users.paul.imports` pattern). The laptop gets its
own `hyprland-monitors.nix` (see above). The rest of the Hyprland config
stays shared.

Deliberately left untouched: `exec-once` starts desktop apps (streamcontroller,
steam, …) — on the laptop the binaries are missing, the calls simply go nowhere,
no misbehavior.

### 6. German keyboard layout starting at the LUKS prompt

`console.keyMap = "de"` is already set in `common/locale.nix`, but does **not**
take effect in the classic (scripted) initrd — the LUKS passphrase would have
to be typed with the US layout. Solution: `boot.initrd.systemd.enable = true`
in the laptop's `boot.nix`. The systemd initrd sets up the console incl. keymap
**before** the passphrase is prompted. In the TTY after boot, `console.keyMap`
applies anyway. The desktop stays unchanged on the scripted initrd.

## Installation procedure

> ⚠️ Wipes the entire disk incl. Fedora and `/home`. Back up data first!

Prerequisites: `paul@10.0.1.46` reachable via SSH key, `paul` can `sudo` on the
laptop (nixos-anywhere uses this to load the kexec installer).

```sh
# Store the LUKS passphrase locally in a file (it gets copied to the installer)
# Prompt for the passphrase instead of writing it into shell history/process list:
umask 077; read -s -p "LUKS passphrase: " pass; printf '%s' "$pass" > /tmp/disk.key; unset pass

nix run github:nix-community/nixos-anywhere -- \
  --flake .#laptop \
  --target-host paul@10.0.1.46 \
  --generate-hardware-config nixos-generate-config ./hosts/laptop/hardware-configuration.nix \
  --disk-encryption-keys /tmp/luks-password /tmp/disk.key
```

`disko.nix` references `/tmp/luks-password` as the `passwordFile` for
formatting; at boot, systemd-cryptsetup interactively prompts for the passphrase.
After installation, commit the generated `hardware-configuration.nix`.

## Error handling / risks

- **Wrong disk:** disko explicitly targets `/dev/nvme0n1` (the only NVMe in the device).
- **Passphrase entry on first boot:** German layout thanks to the systemd initrd;
  still choose the passphrase so that it could also be typed with the US layout
  (insurance against firmware/fallback cases).
- **WLAN after installation:** RTL8852CE needs `enableRedistributableFirmware`;
  NetworkManager comes in via `common/`. First connection possibly via `nmtui`.
- **Hibernate:** `resumeDevice` + swap size (20 GB > 16 GB RAM) are sufficient;
  test after installation: `systemctl hibernate`.

## Test plan

1. `nix flake check` or `nix build .#nixosConfigurations.laptop.config.system.build.toplevel`
   locally — the configuration evaluates and builds.
2. The desktop configuration still builds (`...#nixosConfigurations.desktop...toplevel`),
   in particular **hash-identical** after the SDDM/Hyprland monitor refactoring
   (compare `nix build` before/after — a pure refactoring must not change the
   system; module order can change the ordering in hyprland.conf, in that case
   at least verify the content).
3. After installation: boot with LUKS prompt (verify German layout,
   e.g. special characters), SDDM login, Hyprland on eDP-1 at 1920x1200,
   WLAN, brightness keys, `systemctl hibernate`.

## Out of scope

- Cleaning up the desktop `exec-once` list for the laptop.
- Migrating data from the Fedora `/home`.
- The unused `hosts/desktop/greetd.nix` (stays as-is).

## Addendum (review finding, 2026-07-04)

The Hyprland monitor refactoring also changes the generated
`hyprland.conf` of the **VM** (the removed monitorv2/workspace entries had
no effect there because the VM only has `Virtual-1` — behavior unchanged,
the artifact is not). The verification only compared the desktop hash; the
statement "VM unchanged" holds functionally, not artifact-exact.
