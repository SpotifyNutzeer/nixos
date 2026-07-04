# Laptop-Hostprofil Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neues NixOS-Hostprofil `laptop` (Lenovo IdeaPad, Ryzen 5 7540U) für Remote-Installation per nixos-anywhere — LUKS-verschlüsselt, Hibernate-fähig, gleiches SDDM/Hyprland-Setup wie der Desktop.

**Architecture:** Neuer Host unter `hosts/laptop/` nach dem Muster von `hosts/desktop/`. Partitionierung deklarativ via disko (ESP + LUKS → LVM mit Swap-LV und btrfs-Root). Zwei Refactorings vorab: SDDM wird geteiltes Modul in `common/`, die Desktop-spezifischen Hyprland-Monitore wandern aus der geteilten Home-Manager-Config in Host-Module.

**Tech Stack:** NixOS (nixos-unstable, Flakes), disko, home-manager, nixos-anywhere (nur Doku, Ausführung manuell).

**Spec:** `docs/superpowers/specs/2026-07-04-laptop-host-design.md`

## Global Constraints

- `system.stateVersion = "26.05"`, `networking.hostName = "paul-laptop"`
- Ziel-Disk: `/dev/nvme0n1`; LUKS-Name `cryptroot`; VG `vg0`; Swap-LV 20 GB; `passwordFile = "/tmp/luks-password"`
- Laptop-Display: `eDP-1`, `1920x1200@60`, Position `0x0`, Scale `1.0`
- Desktop- und VM-Verhalten darf sich NICHT ändern (Verifikation per toplevel-Hash bzw. Settings-JSON)
- Code-Kommentare auf Deutsch, wie im Repo üblich
- Verifikations-Zwischendateien nach `/tmp/claude-1000/-home-paul-git-nixos/bbf8f2c5-17f4-4727-b146-942921dd963c/scratchpad/` (unten kurz `$SCRATCH`)

---

### Task 1: SDDM als geteiltes Modul

**Files:**
- Move: `hosts/desktop/sddm.nix` → `common/sddm.nix` (Inhalt unverändert)
- Modify: `hosts/desktop/default.nix` (Import-Pfad)

**Interfaces:**
- Produces: `common/sddm.nix` — NixOS-Modul, das Desktop UND Laptop explizit importieren (bewusst nicht in `common/default.nix`, sonst bekäme die VM einen Login-Manager)

- [ ] **Step 1: Baseline des Desktop-Systems festhalten**

```bash
SCRATCH=/tmp/claude-1000/-home-paul-git-nixos/bbf8f2c5-17f4-4727-b146-942921dd963c/scratchpad
nix build '.#nixosConfigurations.desktop.config.system.build.toplevel' --no-link --print-out-paths > $SCRATCH/desktop-toplevel-baseline.txt
cat $SCRATCH/desktop-toplevel-baseline.txt
```

Expected: ein Store-Pfad (`/nix/store/...-nixos-system-paul-desktop-...`)

- [ ] **Step 2: Datei verschieben**

```bash
git mv hosts/desktop/sddm.nix common/sddm.nix
```

- [ ] **Step 3: Import im Desktop-Profil anpassen**

In `hosts/desktop/default.nix` in der `imports`-Liste ersetzen:

```nix
    ./sddm.nix
```

durch:

```nix
    ../../common/sddm.nix
```

- [ ] **Step 4: Verifizieren — Desktop-System unverändert**

```bash
nix build '.#nixosConfigurations.desktop.config.system.build.toplevel' --no-link --print-out-paths > $SCRATCH/desktop-toplevel-after-t1.txt
diff $SCRATCH/desktop-toplevel-baseline.txt $SCRATCH/desktop-toplevel-after-t1.txt && echo IDENTISCH
```

Expected: `IDENTISCH` (reines Verschieben eines Moduls ändert die Ableitung nicht). Falls abweichend: STOPP, Ursache klären — keine inhaltliche Änderung war beabsichtigt.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move sddm config to shared common module"
```

---

### Task 2: Hyprland-Monitore pro Host (Desktop-Seite)

**Files:**
- Create: `hosts/desktop/hyprland-monitors.nix` (Home-Manager-Modul)
- Modify: `home/program-configs/hyprland.nix` (monitorv2- und workspace-Blöcke entfernen)
- Modify: `hosts/desktop/default.nix` (HM-Import ergänzen)

**Interfaces:**
- Produces: Muster „Host-spezifisches HM-Modul `hyprland-monitors.nix`, injiziert via `home-manager.users.paul.imports`" — Task 4 nutzt dasselbe Muster für den Laptop. Die geteilte `home/program-configs/hyprland.nix` enthält danach KEINE `monitorv2`- und KEINE `workspace`-Liste mehr.

- [ ] **Step 1: Baseline der gemergten Hyprland-Settings festhalten**

```bash
SCRATCH=/tmp/claude-1000/-home-paul-git-nixos/bbf8f2c5-17f4-4727-b146-942921dd963c/scratchpad
nix eval --json '.#nixosConfigurations.desktop.config.home-manager.users.paul.wayland.windowManager.hyprland.settings' > $SCRATCH/hypr-settings-baseline.json
```

Expected: JSON-Ausgabe ohne Fehler.

- [ ] **Step 2: Desktop-Monitor-Modul anlegen**

`hosts/desktop/hyprland-monitors.nix` erstellen — die Blöcke stammen 1:1 aus `home/program-configs/hyprland.nix`:

```nix
{ ... }:
{
  # Desktop-spezifische Monitore + Workspace-Zuordnung (aus der geteilten
  # hyprland.nix herausgezogen; der Laptop hat sein eigenes Pendant).
  wayland.windowManager.hyprland.settings = {
    monitorv2 = [
      {
        output = "HDMI-A-1"; mode = "3840x2160@240.00"; position = "0x1440";
        scale = "1.0"; bitdepth = 10; cm = "hdredid";
        sdr_min_luminance = 0.005; sdr_max_luminance = 250;
        min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22"; vrr = 2;
      }
      {
        output = "DP-2"; mode = "3440x1440@164.90"; position = "0x0";
        bitdepth = 10; cm = "hdredid";
        sdr_min_luminance = 0.005; sdr_max_luminance = 250;
        min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22"; vrr = 2;
      }
      { output = "DP-3"; mode = "2560x720@60"; position = "0x3600"; }
    ];

    workspace = [
      "1, monitor:HDMI-A-1"
      "2, monitor:DP-3"
      "3, monitor:DP-2"
    ];
  };
}
```

- [ ] **Step 3: Blöcke aus der geteilten Config entfernen**

In `home/program-configs/hyprland.nix` innerhalb von `settings`:
1. Die komplette `monitorv2 = [ ... ];`-Liste löschen (der Block zwischen `"$screenshot" = ...` und `env = [`).
2. Die komplette `workspace = [ ... ];`-Liste löschen (der Block zwischen dem `animations`-Attrset und `dwindle = ...`).

Alles andere (env, general, decoration, binds, exec-once, …) bleibt unverändert.

- [ ] **Step 4: HM-Import im Desktop-Profil ergänzen**

In `hosts/desktop/default.nix` die Liste `home-manager.users.paul.imports` erweitern:

```nix
  home-manager.users.paul.imports =
    [
      ./pipewire.nix
      ./fosi-keepalive.nix
      ./rodecaster-tidal-bridge.nix
      ./mangohud.nix
      ./hyprland-monitors.nix
    ];
```

- [ ] **Step 5: Verifizieren — gemergte Settings identisch**

```bash
nix eval --json '.#nixosConfigurations.desktop.config.home-manager.users.paul.wayland.windowManager.hyprland.settings' > $SCRATCH/hypr-settings-after-t2.json
diff $SCRATCH/hypr-settings-baseline.json $SCRATCH/hypr-settings-after-t2.json && echo IDENTISCH
```

Expected: `IDENTISCH`. Falls abweichend: nur akzeptabel, wenn ausschließlich die REIHENFOLGE gleicher Einträge differiert (mit `jq` gegenprüfen); inhaltliche Abweichungen sind ein Fehler.

- [ ] **Step 6: Commit**

```bash
git add hosts/desktop/hyprland-monitors.nix home/program-configs/hyprland.nix hosts/desktop/default.nix
git commit -m "refactor: split hyprland monitor config into per-host modules"
```

---

### Task 3: disko in die Flake

**Files:**
- Modify: `flake.nix` (Input `disko`, Modul in `mkHost`)
- Modify: `flake.lock` (durch `nix flake lock`)

**Interfaces:**
- Consumes: —
- Produces: `disko.nixosModules.disko` ist in JEDEM per `mkHost` gebauten Host geladen; Task 4 kann `disko.devices.*` konfigurieren.

- [ ] **Step 1: Input hinzufügen**

In `flake.nix` im `inputs`-Block (z. B. nach `home-manager`) ergänzen:

```nix
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Output-Argumente und mkHost erweitern**

Die `outputs`-Zeile um `disko` ergänzen:

```nix
  outputs = { self, nixpkgs, home-manager, disko, dotfiles, rodecaster-tidal-bridge, streamcontroller-tidal, tidaluna, nixcord, catppuccin, gsr-ui-nix, ... }:
```

In `mkHost` die `modules`-Liste erweitern (direkt nach `./hosts/${host}`):

```nix
      modules = [
        ./hosts/${host}
        disko.nixosModules.disko
        gsr-ui-nix.nixosModules.default
        ...
```

- [ ] **Step 3: Lockfile aktualisieren**

```bash
nix flake lock
```

Expected: `flake.lock` erhält einen `disko`-Eintrag, keine anderen Inputs werden angefasst.

- [ ] **Step 4: Verifizieren — Desktop-System weiterhin unverändert**

```bash
SCRATCH=/tmp/claude-1000/-home-paul-git-nixos/bbf8f2c5-17f4-4727-b146-942921dd963c/scratchpad
nix build '.#nixosConfigurations.desktop.config.system.build.toplevel' --no-link --print-out-paths > $SCRATCH/desktop-toplevel-after-t3.txt
diff $SCRATCH/desktop-toplevel-baseline.txt $SCRATCH/desktop-toplevel-after-t3.txt && echo IDENTISCH
```

Expected: `IDENTISCH` (das disko-Modul ist ohne `disko.*`-Konfiguration ein No-Op).

- [ ] **Step 5: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat: add disko flake input and module"
```

---

### Task 4: Hostprofil `hosts/laptop/` + Flake-Eintrag

**Files:**
- Create: `hosts/laptop/default.nix`
- Create: `hosts/laptop/hardware-configuration.nix`
- Create: `hosts/laptop/disko.nix`
- Create: `hosts/laptop/boot.nix`
- Create: `hosts/laptop/power.nix`
- Create: `hosts/laptop/hyprland-monitors.nix`
- Modify: `flake.nix` (`nixosConfigurations.laptop`)

**Interfaces:**
- Consumes: `common/sddm.nix` (Task 1), HM-Monitor-Muster (Task 2), disko-Modul (Task 3)
- Produces: `nixosConfigurations.laptop` — baubar; Installation läuft später manuell per nixos-anywhere (siehe Spec, Abschnitt „Installationsablauf")

- [ ] **Step 1: `hosts/laptop/hardware-configuration.nix` anlegen**

```nix
# Platzhalter — wird bei der Installation von nixos-anywhere via
# --generate-hardware-config durch die echte Konfiguration ersetzt.
# Dauerhafte Hardware-Einstellungen (Microcode, Firmware) liegen deshalb
# in boot.nix, damit sie das Ueberschreiben ueberleben.
{ ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
}
```

- [ ] **Step 2: `hosts/laptop/disko.nix` anlegen**

```nix
# Deklaratives Partitionslayout fuer nixos-anywhere/disko.
# ESP + LUKS-Container, darin LVM: 20G Swap (Hibernate) + btrfs-Root.
# passwordFile wird nur beim Formatieren gelesen (nixos-anywhere
# --disk-encryption-keys /tmp/luks-password <lokale Datei>).
{ ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/luks-password";
              settings.allowDiscards = true;   # TRIM auf NVMe durchreichen
              content = {
                type = "lvm_pv";
                vg = "vg0";
              };
            };
          };
        };
      };
    };
    lvm_vg.vg0 = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "20G";   # > 16G RAM, damit das Hibernate-Image sicher passt
          content = { type = "swap"; };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = { mountpoint = "/";     mountOptions = [ "compress=zstd" ]; };
              "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" ]; };
              "/nix"  = { mountpoint = "/nix";  mountOptions = [ "compress=zstd" "noatime" ]; };
            };
          };
        };
      };
    };
  };
}
```

- [ ] **Step 3: `hosts/laptop/boot.nix` anlegen**

```nix
{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # systemd-initrd wendet console.keyMap ("de", common/locale.nix) schon
  # VOR der LUKS-Passphrase-Abfrage an — scripted initrd kann das nicht.
  boot.initrd.systemd.enable = true;

  # Hibernate: Resume aus dem Swap-LV im LUKS-Container (siehe disko.nix).
  boot.resumeDevice = "/dev/vg0/swap";

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;   # u.a. WLAN-Firmware (RTL8852CE)
}
```

- [ ] **Step 4: `hosts/laptop/power.nix` anlegen**

```nix
{ pkgs, ... }:
{
  # TLP fuer Akku-Laufzeit; Defaults reichen fuer den Anfang.
  services.tlp.enable = true;
  # power-profiles-daemon kollidiert mit TLP.
  services.power-profiles-daemon.enable = false;

  # Helligkeitstasten: die Binds (XF86MonBrightness*) existieren bereits
  # in der geteilten Hyprland-Config, es fehlt nur das Tool.
  environment.systemPackages = [ pkgs.brightnessctl ];
}
```

- [ ] **Step 5: `hosts/laptop/hyprland-monitors.nix` anlegen**

```nix
{ ... }:
{
  # Internes Display; Pendant zu hosts/desktop/hyprland-monitors.nix.
  wayland.windowManager.hyprland.settings.monitorv2 = [
    { output = "eDP-1"; mode = "1920x1200@60"; position = "0x0"; scale = "1.0"; }
  ];
}
```

- [ ] **Step 6: `hosts/laptop/default.nix` anlegen**

```nix
{ ... }:
{
  imports = [
    ../../common
    ../../common/sddm.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./boot.nix
    ./power.nix
  ];

  home-manager.users.paul.imports = [ ./hyprland-monitors.nix ];

  networking.hostName = "paul-laptop";
  system.stateVersion = "26.05";
}
```

- [ ] **Step 7: Flake-Eintrag ergänzen**

In `flake.nix` in `nixosConfigurations`:

```nix
    nixosConfigurations = {
      vm      = mkHost "vm";
      desktop = mkHost "desktop";
      laptop  = mkHost "laptop";
    };
```

- [ ] **Step 8: Verifizieren — Laptop-Konfiguration evaluiert korrekt**

```bash
nix eval --raw '.#nixosConfigurations.laptop.config.networking.hostName'; echo
nix eval '.#nixosConfigurations.laptop.config.boot.initrd.systemd.enable'
nix eval --raw '.#nixosConfigurations.laptop.config.boot.resumeDevice'; echo
nix eval --raw '.#nixosConfigurations.laptop.config.console.keyMap'; echo
nix eval --json '.#nixosConfigurations.laptop.config.home-manager.users.paul.wayland.windowManager.hyprland.settings.monitorv2'
nix eval --json '.#nixosConfigurations.laptop.config.fileSystems."/".device'
```

Expected (in dieser Reihenfolge): `paul-laptop`, `true`, `/dev/vg0/swap`, `de`, JSON-Liste mit genau einem Eintrag `output = "eDP-1"`, Root-Device unter `/dev/...vg0...` bzw. mapper-Pfad (von disko gesetzt).

- [ ] **Step 9: Verifizieren — Laptop-System baut**

```bash
nix build '.#nixosConfigurations.laptop.config.system.build.toplevel' --no-link --print-out-paths
```

Expected: Store-Pfad `...-nixos-system-paul-laptop-...`, keine Fehler. (Erster Bau lädt/baut einiges — das darf dauern.)

- [ ] **Step 10: Verifizieren — Desktop weiterhin unverändert**

```bash
SCRATCH=/tmp/claude-1000/-home-paul-git-nixos/bbf8f2c5-17f4-4727-b146-942921dd963c/scratchpad
nix build '.#nixosConfigurations.desktop.config.system.build.toplevel' --no-link --print-out-paths > $SCRATCH/desktop-toplevel-after-t4.txt
diff $SCRATCH/desktop-toplevel-baseline.txt $SCRATCH/desktop-toplevel-after-t4.txt && echo IDENTISCH
```

Expected: `IDENTISCH`.

- [ ] **Step 11: Commit**

```bash
git add hosts/laptop flake.nix
git commit -m "feat: add laptop host profile (disko/LUKS, hibernate, per-host hyprland monitors)"
```

---

## Nach der Implementierung (manuell, nicht Teil des Plans)

Die Installation selbst führt Paul manuell aus (löscht Fedora + `/home`!):

```bash
# Passphrase abfragen statt ins Shell-History/Prozessliste zu schreiben:
umask 077; read -s -p "LUKS-Passphrase: " pass; printf '%s' "$pass" > /tmp/disk.key; unset pass
nix run github:nix-community/nixos-anywhere -- \
  --flake .#laptop \
  --target-host paul@10.0.1.46 \
  --generate-hardware-config nixos-generate-config ./hosts/laptop/hardware-configuration.nix \
  --disk-encryption-keys /tmp/luks-password /tmp/disk.key
```

Danach: generierte `hardware-configuration.nix` committen; am Gerät LUKS-Prompt
mit deutschem Layout (Sonderzeichen!), SDDM, eDP-1-Auflösung, WLAN und
`systemctl hibernate` testen.
