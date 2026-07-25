# VR/OpenXR (Pico 4 + WiVRn + xrizer) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SteamVR-Spiele (Proton) auf paul-desktop in VR spielen, gestreamt auf eine Pico 4 — vollständig deklarativ, ohne SteamVR.

**Architecture:** WiVRn (Monado-basiert) läuft als systemd-User-Service auf dem Desktop-Host und ist zugleich OpenXR-Runtime und Streaming-Server. Das nixpkgs-Paket bündelt xrizer als OpenVR→OpenXR-Layer und verwaltet `active_runtime.json`/`openvrpaths.vrpath` selbst. Die Pico 4 verbindet sich per WLAN über die WiVRn-Client-App (mDNS-Discovery).

**Tech Stack:** NixOS-Modul `services.wivrn` (wivrn 26.6.2), xrizer 0.5 (im Paket gebündelt), wayvr, android-tools, PipeWire (vorhanden).

**Spec:** `docs/superpowers/specs/2026-07-25-vr-openxr-pico4-design.md`

## Global Constraints

- Nur Host `desktop` (flake-Attribut `desktop`, Hostname `paul-desktop`) — Laptop/MacBook unberührt.
- Kein SteamVR, kein ALVR, kein CUDA-Build von wivrn (`config` des Moduls bleibt leer; Encoder/Bitrate werden zur Laufzeit im WiVRn-Dashboard eingestellt).
- Kommentar-Stil des Repos: Deutsch, Umlaute ASCII-umschrieben (`fuer`, `noetig`).
- Rebuild-Kommando: `sudo nixos-rebuild switch --flake /home/paul/git/nixos#desktop`

---

### Task 1: WiVRn-Modul aktivieren (`hosts/desktop/vr.nix`)

**Files:**
- Create: `hosts/desktop/vr.nix`
- Modify: `hosts/desktop/default.nix` (Import-Liste, nach `./streamcontroller.nix`)

**Interfaces:**
- Consumes: bestehende Module `hosts/desktop/nvidia.nix` (`hardware.graphics.enable`), `gaming.nix` (`programs.steam`), PipeWire.
- Produces: laufender `wivrn.service` (systemd user) mit Port 9757, systemweite OpenXR-Runtime, `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1` als Session-Variable. Task 2 verlässt sich darauf.

- [ ] **Step 1: Baseline prüfen — aktueller Build ist grün**

Run: `nix build /home/paul/git/nixos#nixosConfigurations.desktop.config.system.build.toplevel --no-link`
Expected: Erfolg ohne Fehler (Baseline; Fehler hier sind nicht von uns).

- [ ] **Step 2: `hosts/desktop/vr.nix` anlegen**

```nix
{ pkgs, ... }:
{
  # WiVRn: OpenXR-Runtime + Streaming-Server (Monado-basiert) fuer die Pico 4.
  # xrizer ist im Paket als OpenVR-Compat-Layer gebuendelt; der Server
  # verwaltet active_runtime.json und openvrpaths.vrpath selbst — SteamVR
  # wird nicht installiert. Avahi/mDNS aktiviert das Modul automatisch.
  services.wivrn = {
    enable = true;
    openFirewall = true;             # 9757 TCP/UDP fuer den Stream
    autoStart = true;                # Server startet mit der User-Session
    highPriority = true;             # CAP_SYS_NICE fuer Async-Reprojection
    # Runtime in der Steam-Pressure-Vessel-Sandbox sichtbar machen
    # (steam.enable ist default-an). Wird erst nach Re-Login wirksam.
    steam.importOXRRuntimes = true;
    # config/monadoEnvironment bewusst leer: Vulkan-Encode laeuft auf NVIDIA
    # ohne CUDA-Build, Encoder/Bitrate stellt man im WiVRn-Dashboard ein.
  };

  environment.systemPackages = with pkgs; [
    wayvr          # Desktop-Overlay in VR (Nachfolger von wlx-overlay-s)
    android-tools  # adb fuer die einmalige Client-Installation aufs Headset
  ];
}
```

- [ ] **Step 3: Import in `hosts/desktop/default.nix` ergänzen**

In der `imports`-Liste nach `./streamcontroller.nix` einfügen:

```nix
    ./vr.nix
```

- [ ] **Step 4: Build verifizieren**

Run: `nix build /home/paul/git/nixos#nixosConfigurations.desktop.config.system.build.toplevel --no-link`
Expected: Erfolg. (Lädt wivrn/wayvr aus dem Binary-Cache — kann ein paar Minuten dauern.)

- [ ] **Step 5: Commit**

```bash
cd /home/paul/git/nixos
git add hosts/desktop/vr.nix hosts/desktop/default.nix
git commit -m "desktop: add VR/OpenXR via WiVRn (Pico 4 streaming)"
```

---

### Task 2: Aktivieren + Server-Smoke-Test

**Files:** keine (Aktivierung + Verifikation)

**Interfaces:**
- Consumes: Task 1 (Konfiguration im Repo).
- Produces: laufender WiVRn-Server auf paul-desktop; Voraussetzung für Task 3.

- [ ] **Step 1: System aktivieren**

Run: `sudo nixos-rebuild switch --flake /home/paul/git/nixos#desktop`
Expected: Aktivierung ohne Fehler.

- [ ] **Step 2: User-Service prüfen**

Run: `systemctl --user status wivrn.service --no-pager`
Expected: `active (running)`. Falls `inactive`: einmalig `systemctl --user start wivrn.service` (autoStart greift ab der nächsten Session) und erneut prüfen.

- [ ] **Step 3: Port + mDNS prüfen**

Run: `ss -tlnp | grep 9757 && avahi-browse -t _wivrn._tcp`
Expected: Listener auf 9757 und ein Avahi-Eintrag `paul-desktop` für `_wivrn._tcp`.

- [ ] **Step 4: OpenXR-Runtime registriert?**

Run: `cat /etc/xdg/openxr/1/active_runtime.json 2>/dev/null || cat ~/.config/openxr/1/active_runtime.json`
Expected: JSON, dessen `library_path` auf WiVRn/Monado im Nix-Store zeigt.

- [ ] **Step 5: Re-Login fuer Steam-Env**

Einmal aus Hyprland ab- und wieder anmelden, dann:
Run: `systemctl --user show-environment | grep PRESSURE_VESSEL`
Expected: `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1`

---

### Task 3: Pico-4-Client installieren + Verbindung (manuell, mit Paul)

**Files:** keine (Headset-Seite, einziger nicht-deklarativer Teil)

**Interfaces:**
- Consumes: Task 2 (laufender Server, adb installiert).
- Produces: gekoppeltes Headset; Voraussetzung für Task 4.

- [ ] **Step 1: Server-Version feststellen**

Run: `wivrn-server --version 2>/dev/null || nix eval /home/paul/git/nixos#nixosConfigurations.desktop.pkgs.wivrn.version`
Expected: `26.6.2` — die Client-APK muss zur selben Major-Version gehören.

- [ ] **Step 2: Client-APK laden**

Von https://github.com/WiVRn/WiVRn/releases das Asset `WiVRn-standard-release.apk` des Tags herunterladen, der zur Server-Version passt (v26.6.x).

- [ ] **Step 3: Developer-Mode auf der Pico 4 (macht Paul am Headset)**

Einstellungen → Allgemein → Info → 7× auf die Versionsnummer tippen → Entwickleroptionen erscheinen → USB-Debugging aktivieren.

- [ ] **Step 4: APK installieren**

Headset per USB-C an den PC, Debugging-Prompt im Headset bestätigen, dann:

```bash
adb devices        # Geraet muss als "device" (nicht "unauthorized") erscheinen
adb install ~/Downloads/WiVRn-standard-release.apk
```

Expected: `Success`.

- [ ] **Step 5: Verbinden**

WiVRn-App auf der Pico starten (Bibliothek → Unbekannte Quellen). Der PC `paul-desktop` erscheint per mDNS; verbinden und die Kopplung auf dem PC im WiVRn-Dashboard (`wivrn-dashboard`) bestätigen.
Expected: Headset zeigt die leere Monado-Szene; Dashboard zeigt aktive Verbindung.

---

### Task 4: End-to-End-Test mit einem SteamVR-Spiel (manuell, mit Paul)

**Files:** keine

**Interfaces:**
- Consumes: Task 3 (gekoppeltes Headset), `programs.steam` aus `gaming.nix`.
- Produces: verifiziertes Gesamt-Setup — Erfolgskriterium 3 des Specs.

- [ ] **Step 1: Steam nach Re-Login starten, VR-Spiel starten**

Headset verbunden lassen, in Steam ein SteamVR-Spiel aus der Bibliothek starten (ohne besondere Launch-Options).
Expected: Spiel rendert im Headset, Controller funktionieren, Audio läuft über das WiVRn-PipeWire-Sink.

- [ ] **Step 2: Fallback dokumentiert (nur falls Step 1 die Runtime nicht findet)**

Launch-Option für das betroffene Spiel:

```
PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

- [ ] **Step 3: Abschluss-Commit (nur falls unterwegs Doku/Config angepasst wurde)**

```bash
cd /home/paul/git/nixos
git add -A docs hosts/desktop
git commit -m "desktop: finalize WiVRn VR setup"
```
