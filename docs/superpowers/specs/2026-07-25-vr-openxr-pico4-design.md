# VR/OpenXR auf paul-desktop (Pico 4 + WiVRn + xrizer)

Datum: 2026-07-25 · Status: approved

## Ziel

SteamVR-Spiele (Proton) auf dem Desktop (NVIDIA, Hyprland/Wayland) in VR spielen,
gestreamt auf eine Pico 4 per WLAN (PC an Ethernet, Headset im 5-GHz-WLAN).
Vollständig deklarativ, ohne SteamVR: WiVRn ist die OpenXR-Runtime und der
Streaming-Server, xrizer übersetzt die OpenVR-API der SteamVR-Spiele nach OpenXR.

```
Pico 4 (WiVRn-Client-App)
   │  5-GHz-WLAN ←→ Router ←→ Ethernet
   ▼
WiVRn-Server (systemd user service, OpenXR-Runtime, Monado-basiert)
   ▲                    ▲
   │ OpenXR             │ OpenXR
native OpenXR-Apps    xrizer (OpenVR → OpenXR)
                        ▲
                        │ OpenVR-API
                      SteamVR-Spiele unter Proton
```

Verwendete Pakete aus dem gepinnten nixpkgs: `wivrn` 26.6.2 (mit NixOS-Modul
`services.wivrn` inkl. Steam-Integration), `xrizer` 0.5.

## Design

### 1. WiVRn-Server (`hosts/desktop/vr.nix`, neu)

Nur auf dem Desktop-Host, Import in `hosts/desktop/default.nix` — analog zu
`gaming.nix` & Co.

- `services.wivrn`:
  - `enable`, `openFirewall` (Port 9757 TCP/UDP), `autoStart` (Server startet
    mit der User-Session), `highPriority` (CAP_SYS_NICE fürs Compositing).
  - `steam.importOXRRuntimes`: exportiert
    `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1`, damit Proton-Spiele in der
    Steam-Sandbox die Runtime erreichen (`steam.enable` ist default-an).
  - `config` bleibt leer: Das Stock-Paket kann Vulkan-Video-Encode
    (Hardware-Encoding auf NVIDIA ohne CUDA-Build); Encoder/Bitrate werden zur
    Laufzeit im WiVRn-Dashboard eingestellt. NVENC bräuchte einen
    unfreien, ungecachten CUDA-Build — YAGNI.
  - `monadoEnvironment`: leer; nur bei konkreten NVIDIA-Problemen setzen.
- Avahi/mDNS fürs Auto-Discovery aktiviert das Modul selbst mit.
- Tools als `environment.systemPackages`: `wayvr` (Desktop-Overlay in VR,
  Nachfolger von wlx-overlay-s), `android-tools` (adb für die einmalige
  Client-Installation; USB-Zugriff kommt über systemd-uaccess-Regeln).

### 2. xrizer als OpenVR-„Treiber" (keine eigene Konfig nötig)

Das nixpkgs-WiVRn-Paket bündelt xrizer als Standard-Eintrag im
`OVR_COMPAT_SEARCH_PATH`; der WiVRn-Server verwaltet
`~/.config/openvr/openvrpaths.vrpath` und die aktive OpenXR-Runtime selbst
(deshalb wurde die frühere Modul-Option `defaultRuntime` entfernt). Es ist
keine home-manager-Konfiguration nötig — SteamVR-Spiele landen automatisch
bei xrizer, sobald der WiVRn-Server läuft.

### 3. Spiele-Start (Doku, keine Konfig)

- Durch `services.wivrn.steam.enable` ist keine Launch-Option nötig; falls ein
  Spiel den Socket doch nicht sieht, ist der dokumentierte Fallback:
  `PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%`
- Native OpenXR-Spiele brauchen nichts weiter (Runtime ist systemweit gesetzt).
- Audio + Mikrofon laufen über PipeWire; WiVRn legt beim Verbinden ein eigenes
  Sink/Source-Paar an und routet automatisch.

### 4. Headset-Seite (einmalig, manuell — einziger nicht-deklarativer Teil)

1. Pico 4: Developer-Mode aktivieren (Einstellungen → Allgemein → Info,
   mehrfach auf die Versionsnummer tippen, dann Entwickleroptionen → USB-Debugging).
2. WiVRn-Client-APK vom WiVRn-GitHub-Release passend zur Server-Version laden.
3. Headset per USB an den PC, `adb install wivrn-client…apk`, Debugging-Prompt
   im Headset bestätigen.
4. App auf der Pico starten — der PC erscheint via mDNS automatisch; Verbindung
   einmalig im WiVRn-Dashboard auf dem PC bestätigen.

Wichtig: Client- und Server-Version müssen zusammenpassen; nach einem
nixpkgs-Update mit neuer WiVRn-Version ggf. Client-APK aktualisieren.

## Verifikation

1. `nix build` der Desktop-Konfiguration schlägt nicht fehl; nach Rebuild läuft
   `wivrn.service` (user) und lauscht auf 9757.
2. Pico 4 findet den PC automatisch, verbindet sich; WiVRn-Dashboard zeigt den
   Stream, Headset zeigt die Monado-Void-Scene.
3. Ein SteamVR-Spiel aus der Bibliothek startet über Proton, rendert im Headset,
   Controller und Audio (PipeWire) funktionieren.

## Nicht im Scope

ALVR/SteamVR-Fallback, Lighthouse-/Full-Body-Tracking, Sim-Racing-Spezifika,
Laptop-Host. Alles später nachrüstbar; bei Spielen, die mit xrizer nicht
laufen, ist ALVR + SteamVR der dokumentierte Plan B.
