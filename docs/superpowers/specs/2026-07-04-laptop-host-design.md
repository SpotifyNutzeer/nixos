# Design: Hostprofil `laptop` (Lenovo IdeaPad, 10.0.1.46)

**Datum:** 2026-07-04
**Status:** Entwurf validiert (Brainstorming abgeschlossen)

## Ziel

Ein neues NixOS-Hostprofil `laptop` für den Lenovo-Laptop (aktuell Fedora 42,
erreichbar via SSH unter `paul@10.0.1.46`), installiert per **nixos-anywhere**
über SSH. Der Laptop bekommt dasselbe grafische Setup wie der Desktop
(SDDM + Hyprland + Catppuccin), ergänzt um Laptop-Spezifika.

## Hardware (per SSH ermittelt)

| Komponente | Wert |
|---|---|
| Gerät | Lenovo 82X3 (IdeaPad) |
| CPU/GPU | AMD Ryzen 5 7540U mit Radeon 740M (integriert, Phoenix) |
| RAM | 16 GB |
| Disk | 1 TB NVMe (`/dev/nvme0n1`) |
| Display | eDP-1, 1920x1200 nativ |
| WLAN | Realtek RTL8852CE (Kernel-Support vorhanden) |
| Firmware | UEFI |

## Entscheidungen

1. **Installation:** nixos-anywhere (Remote über SSH, löscht die Platte komplett —
   Fedora und `/home` gehen verloren; Daten vorher sichern).
2. **Verschlüsselung:** LUKS-Vollverschlüsselung, eine Passphrase beim Boot.
3. **Grafisches Setup:** wie Desktop — SDDM wird geteiltes Modul.
4. **Swap:** 20-GB-Swap-Partition **innerhalb** von LUKS, Hibernate-fähig.
5. **Hostname:** `paul-laptop`.

## Architektur

### 1. Flake-Änderungen (`flake.nix`)

- Neuer Input `disko` (`github:nix-community/disko`, `inputs.nixpkgs.follows = "nixpkgs"`).
- `disko.nixosModules.disko` in die `mkHost`-Modulliste (harmlos für `desktop`/`vm`,
  die kein `disko.*` konfigurieren).
- `nixosConfigurations.laptop = mkHost "laptop"`.

### 2. Festplattenlayout (`hosts/laptop/disko.nix`)

GPT auf `/dev/nvme0n1`:

- **ESP:** 1 GB, vfat, gemountet als `/boot`.
- **LUKS-Container `cryptroot`** (Rest der Platte), darin LVM (VG `vg0`):
  - **LV `swap`:** 20 GB Swap (Hibernate-Image liegt damit verschlüsselt).
  - **LV `root`:** Rest, btrfs mit Subvolumes `/root` (→ `/`), `/home`, `/nix`,
    jeweils `compress=zstd`, `/nix` zusätzlich `noatime`.

Eine Passphrase entsperrt den Container; Swap und Root hängen am selben LUKS.

### 3. Hostprofil (`hosts/laptop/`)

- **`default.nix`** — importiert `../../common`, `../../common/sddm.nix`,
  `./hardware-configuration.nix`, `./disko.nix`, `./boot.nix`, `./power.nix`;
  injiziert `./hyprland-monitors.nix` via `home-manager.users.paul.imports`;
  `networking.hostName = "paul-laptop"`; `system.stateVersion = "26.05"`.
- **`boot.nix`** — systemd-boot, `configurationLimit`, zen-Kernel (wie Desktop);
  **`boot.initrd.systemd.enable = true`** (siehe Tastaturlayout);
  `boot.resumeDevice` auf das Swap-LV (`/dev/vg0/swap`) für Hibernate.
- **`hardware-configuration.nix`** — wird bei der Installation von nixos-anywhere
  generiert (`--generate-hardware-config`) und dabei überschrieben; bis dahin
  Platzhalter mit `nixpkgs.hostPlatform = "x86_64-linux"`. Deshalb liegen
  `hardware.cpu.amd.updateMicrocode = true` und
  `hardware.enableRedistributableFirmware = true` (WLAN-Firmware) dauerhaft in
  `boot.nix`, nicht hier.
- **`power.nix`** — `services.tlp.enable = true` (Akku-Laufzeit),
  `brightnessctl` als Systempaket (Helligkeitstasten sind in der Hyprland-Config
  schon gebunden), `services.logind`-Defaults für Deckel-zu → Suspend.
  AMD-GPU braucht keine Extra-Konfiguration (Mesa ist Standard).
- **`hyprland-monitors.nix`** — Home-Manager-Modul:
  `monitorv2 = [{ output = "eDP-1"; mode = "1920x1200@60"; position = "0x0"; scale = "1.0"; }]`.

### 4. SDDM wird geteiltes Modul

- `hosts/desktop/sddm.nix` → **`common/sddm.nix`** (inhaltlich unverändert,
  inkl. Catppuccin und gnome-keyring).
- Bewusst **nicht** in `common/default.nix` aufgenommen — sonst bekäme die VM
  einen Login-Manager. Desktop und Laptop importieren es explizit.

### 5. Hyprland-Monitore pro Host

Die `monitorv2`-Einträge (HDMI-A-1, DP-2, DP-3) und die Workspace-Bindings
(`1, monitor:HDMI-A-1` usw.) sind Desktop-spezifisch, liegen aber in der
geteilten `home/program-configs/hyprland.nix`. Sie wandern in
**`hosts/desktop/hyprland-monitors.nix`** (HM-Modul, injiziert über das
bestehende `home-manager.users.paul.imports`-Muster). Der Laptop bekommt sein
eigenes `hyprland-monitors.nix` (siehe oben). Der Rest der Hyprland-Config
bleibt geteilt.

Bewusst unangetastet: `exec-once` startet Desktop-Apps (streamcontroller,
steam, …) — auf dem Laptop fehlen die Binaries, die Aufrufe laufen ins Leere,
kein Fehlverhalten.

### 6. Deutsches Tastaturlayout ab dem LUKS-Prompt

`console.keyMap = "de"` steht bereits in `common/locale.nix`, greift im
klassischen (scripted) Initrd aber **nicht** — die LUKS-Passphrase müsste mit
US-Layout eingetippt werden. Lösung: `boot.initrd.systemd.enable = true` im
Laptop-`boot.nix`. Das systemd-Initrd richtet die Konsole inkl. Keymap ein,
**bevor** die Passphrase abgefragt wird. Im TTY nach dem Boot gilt ohnehin
`console.keyMap`. Der Desktop bleibt unverändert beim scripted Initrd.

## Installationsablauf

> ⚠️ Löscht die komplette Platte inkl. Fedora und `/home`. Vorher Daten sichern!

Voraussetzungen: `paul@10.0.1.46` per SSH-Key erreichbar, `paul` kann auf dem
Laptop `sudo` (nixos-anywhere lädt darüber den kexec-Installer).

```sh
# LUKS-Passphrase lokal in Datei ablegen (wird auf den Installer kopiert)
# Passphrase abfragen statt ins Shell-History/Prozessliste zu schreiben:
umask 077; read -s -p "LUKS-Passphrase: " pass; printf '%s' "$pass" > /tmp/disk.key; unset pass

nix run github:nix-community/nixos-anywhere -- \
  --flake .#laptop \
  --target-host paul@10.0.1.46 \
  --generate-hardware-config nixos-generate-config ./hosts/laptop/hardware-configuration.nix \
  --disk-encryption-keys /tmp/luks-password /tmp/disk.key
```

`disko.nix` referenziert `/tmp/luks-password` als `passwordFile` für das
Formatieren; beim Boot fragt systemd-cryptsetup interaktiv nach der Passphrase.
Nach der Installation die generierte `hardware-configuration.nix` committen.

## Fehlerbehandlung / Risiken

- **Falsche Platte:** disko zielt explizit auf `/dev/nvme0n1` (einzige NVMe im Gerät).
- **Passphrase-Eingabe beim ersten Boot:** dank systemd-Initrd mit deutschem Layout;
  Passphrase trotzdem so wählen, dass sie auch mit US-Layout eintippbar wäre
  (Versicherung gegen Firmware-/Fallback-Fälle).
- **WLAN nach Installation:** RTL8852CE braucht `enableRedistributableFirmware`;
  NetworkManager kommt über `common/`. Erste Verbindung ggf. per `nmtui`.
- **Hibernate:** `resumeDevice` + Swap-Größe (20 GB > 16 GB RAM) sind ausreichend;
  Test nach Installation: `systemctl hibernate`.

## Testplan

1. `nix flake check` bzw. `nix build .#nixosConfigurations.laptop.config.system.build.toplevel`
   lokal — Konfiguration evaluiert und baut.
2. Desktop-Konfiguration baut weiterhin (`...#nixosConfigurations.desktop...toplevel`),
   insbesondere nach dem SDDM-/Hyprland-Monitor-Refactoring **hash-gleich**
   (`nix build` vorher/nachher vergleichen — reines Refactoring darf das System
   nicht ändern; Modul-Reihenfolge kann die Reihenfolge in hyprland.conf ändern,
   dann zumindest inhaltlich prüfen).
3. Nach der Installation: Boot mit LUKS-Prompt (deutsches Layout verifizieren,
   z. B. Sonderzeichen), SDDM-Login, Hyprland auf eDP-1 mit 1920x1200,
   WLAN, Helligkeitstasten, `systemctl hibernate`.

## Out of Scope

- Aufräumen der Desktop-`exec-once`-Liste für den Laptop.
- Migration von Daten aus dem Fedora-`/home`.
- Ungenutztes `hosts/desktop/greetd.nix` (bleibt liegen).

## Nachtrag (Review-Befund, 2026-07-04)

Das Refactoring der Hyprland-Monitore ändert auch die generierte
`hyprland.conf` der **VM** (die entfernten monitorv2-/workspace-Einträge waren
dort wirkungslos, weil die VM nur `Virtual-1` hat — Verhalten unverändert,
Artefakt nicht). Die Verifikation hat nur den Desktop-Hash verglichen; die
Aussage „VM unverändert" gilt funktional, nicht artefakt-genau.
