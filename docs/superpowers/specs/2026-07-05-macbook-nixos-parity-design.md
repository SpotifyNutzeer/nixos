# MacBook-Setup mit NixOS-Parität — Design-Spec

**Datum:** 2026-07-05
**Ziel-Host:** MacBook Pro (M4 Pro, `aarch64-darwin`)
**Status:** Design freigegeben, bereit für Implementierungsplan

## Ziel

Ein macOS-Setup, das so nah wie möglich am bestehenden NixOS/Hyprland-Setup liegt —
gleiche Keybinds, gleiches Tiling-Gefühl, identischer Terminal-/Shell-/Editor-/Theming-Stack,
verwaltet aus **demselben** Flake. yabai wurde verworfen (fühlt sich clunky an, kämpft gegen
den WindowServer, braucht teils SIP-Disable). Stattdessen AeroSpace als deterministischer,
i3-artiger Tiling-WM.

## Grundprinzip: zwei Ebenen

1. **Tool-Stack (~80% der Config): 1:1 portierbar.** kitty, tmux, fish, starship, vim, ssh,
   hyfetch, alacritty, claude-code, Catppuccin-Themes — allesamt home-manager-Module, die auf
   macOS identisch laufen. Kommen nach `shared/` und gelten auf beiden Systemen.
2. **Window-Manager-Schicht: neu nachgebaut.** Hyprland ist ein Wayland-Compositor und läuft
   nicht auf macOS. Portierbar ist das *Tiling-Verhalten und die Keybinds* (AeroSpace), nicht
   der Compositor.

## Bestätigte Entscheidungen

| Thema | Entscheidung |
|---|---|
| Scope | MVP zuerst, dann Feinschliff (2 Phasen) |
| Modifier-Taste | **Alt/Option (⌥)** ersetzt SUPER |
| Launcher | Sol/Ueli (Phase 2); im MVP bleibt Raycast, Hotkey auf `alt-shift-enter` |
| Repo-Struktur | Dieses Repo erweitern; `darwinConfigurations`-Output; Modul-Split shared/linux/darwin |
| Hardware | M4 Pro → `aarch64-darwin` |
| Scratchpad/Special-Workspace | vorerst weggelassen |
| Media/Brightness-Keys | bleiben nativ macOS |
| Statusleiste | SketchyBar, **kein** 1:1-Port von quickshell (Notch + andere Engine) |

## Architektur

### Flake-Erweiterung (`flake.nix`)

- Neuer Input: `nix-darwin` (folgt `nixpkgs`).
- Neuer Output: `darwinConfigurations.<host>` für `aarch64-darwin`.
- home-manager wird als `nix-darwin`-Modul eingehängt (analog zum bestehenden
  `home-manager.nixosModules.home-manager`-Muster), sodass **ein** `darwin-rebuild switch`
  System + Home baut.
- `catppuccin`-Input läuft auf `aarch64-darwin` — kein zusätzlicher Input nötig.

### Modul-Split (`home/program-configs/`)

| Kategorie | Module | Import durch |
|---|---|---|
| **shared/** (portabel) | starship, fish, vim, kitty, alacritty, tmux, ssh, hyfetch, claude-code, brave, Catppuccin-Palette + App-Themes | Linux **und** Mac |
| **linux/** | hyprland, hyprlock, quickshell, rofi, xdg-mime, qt/gtk/kvantum-Theming, Cursor-Themes | nur NixOS |
| **darwin/** | aerospace, sketchybar (Phase 2), borders (Phase 2) | nur Mac |

- `home.nix` → `home-shared.nix` + `home-linux.nix` + `home-darwin.nix`.
  Die beiden Plattform-Dateien importieren `home-shared.nix`.
- `home.homeDirectory` wird plattformabhängig: `/home/paul` (Linux) vs. `/Users/paul` (macOS).
- **Grenze der Deklarativität:** Nicht alles auf dem Mac ist über Nix abbildbar
  (Sol/Ueli-GUI-Settings, einige Systemtweaks). nix-darwin deckt vieles über `system.defaults`
  ab; der Rest wird als expliziter „manueller Schritt" dokumentiert, nicht versteckt.

## WM-Schicht: AeroSpace (`home/program-configs/darwin/aerospace.nix`)

Über `programs.aerospace.settings` (home-manager erzeugt die TOML). Modifier = **Alt (⌥)**.

### Keybind-Mapping Hyprland → AeroSpace

| Hyprland | AeroSpace | Status |
|---|---|---|
| `SUPER+Return` → kitty | `alt-enter` → `exec-and-forget open -na kitty` | 1:1 |
| `SUPER+SHIFT+Q` killactive | `alt-shift-q` → `close` | 1:1 |
| `SUPER+F` fullscreen | `alt-f` → `fullscreen` | 1:1 |
| `SUPER+V` togglefloating | `alt-v` → `layout floating tiling` | 1:1 |
| `SUPER+J` togglesplit | `alt-j` → `layout tiles horizontal vertical` | nah |
| `SUPER+←↑→↓` movefocus | `alt-left/up/right/down` → `focus` | 1:1 |
| `SUPER+1..0` workspace | `alt-1..0` → `workspace 1..10` | 1:1 |
| `SUPER+SHIFT+1..0` move | `alt-shift-1..0` → `move-node-to-workspace 1..10` | 1:1 |
| `SUPER+SHIFT+Return` → menu | `alt-shift-enter` → Launcher-Hotkey | 1:1 (Raycast im MVP) |
| `SUPER+E` → Dateimanager | `alt-e` → `exec-and-forget open -a Finder` | 1:1 |
| `SUPER+S` special/scratchpad | — | weggelassen |
| `SUPER+mouse` workspace-scroll | — | nicht möglich in AeroSpace |
| `bindm` Fenster move/resize (Maus) | nativ macOS | entfällt |
| `bindel`/`bindl` Volume/Brightness/Media | nativ macOS | entfällt |

### Layout-Angleichung

- Gaps: `inner=5`, `outer=10` (passend zu `gaps_in=5 / gaps_out=10`).
- Default-Layout `tiles` (entspricht dem dwindle-Tiling-Baum).

### JankyBorders (`darwin/borders.nix`, Phase 2)

- Ersetzt Hyprlands Gradient-Border (`col.active_border = $sky $teal 45deg`).
- borders mit Gradient in Sky (`rgb(89dceb)`) → Teal (`rgb(94e2d5)`).
- Start via AeroSpace `after-startup-command = ['exec-and-forget borders …']`.

### Ehrliche Grenzen der WM-Schicht

- Kein Compositor-weiter Blur über Fremdfenster, keine Fenster-Animationen, kein echter
  Compositor — macOS-WindowServer-bedingt.
- Scratchpad nur emulierbar (vorerst weggelassen).
- Mausgesten-Workspace-Scroll fällt weg.

## Statusleiste: SketchyBar (`darwin/sketchybar.nix`, Phase 2)

**Kein 1:1-Port von quickshell** — bewusst, aus zwei Gründen:

1. **Notch (M4 Pro):** Kamera-Notch oben mittig. Items werden in eine linke und eine rechte
   Gruppe gelegt, die **Mitte bleibt frei**. Gewähltes Layout: Bar über volle Breite, Mitte
   ausgespart (statt schmaler Bar unter der Notch — verschenkt Platz).
2. **Andere Engine:** quickshell (QML) vs. SketchyBar (Lua-Items via SbarLua). Übernommen
   werden **Inhalte & Optik**, nicht der Code.

- Lua-API (SbarLua) statt Shell — wartbarer, näher an quickshells strukturiertem Ansatz.
- Config via home-manager `xdg.configFile`.
- Inhalte (an quickshell angelehnt): AeroSpace-Workspace-Indikator links (reagiert auf
  `exec-on-workspace-change`), aktiver Fenstertitel, rechts Uhr/Datum/Akku/WLAN/Lautstärke,
  Catppuccin-Mocha-Look.
- **Bar-Blur:** SketchyBars eigener `blur_radius` wird gesetzt (fängt einen Teil des
  Glas-Effekts ab, den Hyprlands globaler Blur bot).

## Launcher (Phase 2)

Im MVP bleibt Raycast, Hotkey auf `alt-shift-enter` gelegt (Reflex sitzt).

In Phase 2 Evaluierung Sol vs. Ueli:

| | Sol | Ueli |
|---|---|---|
| Feel | nativ, sehr snappy (am nächsten an rofi) | Electron, etwas träger |
| Config | GUI-lastig, wenig deklarierbar | JSON-Datei → via `xdg.configFile` deklarierbar |
| Scripting (dmenu-Ersatz) | begrenzt | ja, Skript-Extensions |

**Empfehlung:** Erst Sol antesten (rofi-*Gefühl* war Hauptkriterium); Ueli als Fallback, falls
Deklarierbarkeit/Scripting wichtiger wird. Beide Wege bleiben offen; nur der Hotkey ist fix.
Falls nicht in nixpkgs → via nix-darwin `homebrew.casks`, dokumentiert.

## Theming

- **Catppuccin Mocha** (`catppuccin/nix`, läuft auf `aarch64-darwin`).
- Palette + App-Themes (kitty, fish, starship, tmux, vim, bat, …) nach `shared/` →
  Terminal/Shell/Editor **pixelidentisch** auf beiden Systemen.
- Linux-only (in `linux/theming.nix`): qt6ct, kvantum, GTK-Theming, Cursor-Themes
  (`catppuccin-mocha-teal-cursors`) — X11/Wayland-Konzepte ohne macOS-Pendant.
- Mac: natives Erscheinungsbild via `system.defaults` (Dark Mode).
- Neu auf Mac im Catppuccin-Look: SketchyBar-Farben, JankyBorders-Gradient (Sky→Teal).

## kitty-Blur auf macOS

Wichtige Korrektur zur pauschalen „kein Blur"-Aussage:

- **Compositor-Blur (Hyprland):** blurrt alles hinter jedem Fenster/Layer — auf macOS für
  Fremdfenster **nicht** verfügbar.
- **App-eigener Blur (kitty):** kitty rendert seinen Hintergrund-Blur selbst über native
  macOS-APIs, unabhängig vom Compositor — **funktioniert auf macOS**.

Konkret in `shared/kitty.nix` (`programs.kitty.settings`):

```
background_opacity = "0.9";
background_blur    = 32;   # auf macOS zugleich Blur-Radius; Werte bis ~64 laufen gut
```

Damit sieht kitty auf dem Mac praktisch wie unter Hyprland aus (transparent + geblurrt). Unter
Hyprland macht den Blur der Compositor, auf dem Mac kitty selbst — dieselbe `shared/`-Config.
**Nicht** erreichbar bleibt, dass Fremd-Apps (Brave, Finder) durchblurren wie bei Hyprlands
globalem Blur.

## Phasen

### Phase 1 — MVP (lauffähig, benutzbar)

1. `flake.nix`: `nix-darwin`-Input + `darwinConfigurations.<host>` (`aarch64-darwin`);
   home-manager als darwin-Modul.
2. Modul-Split: `home/program-configs/` → `shared/`, `linux/`, `darwin/`;
   `home.nix` → `home-shared.nix` + `home-linux.nix` + `home-darwin.nix`.
3. Portable Module auf Mac aktiv & verifiziert: kitty (inkl. `background_blur`/
   `background_opacity`), tmux, fish, starship, vim, ssh, hyfetch, alacritty, claude-code.
4. `darwin/aerospace.nix`: Keybind-Mapping (Alt-Modifier, Workspaces 1–10, Focus, Move,
   Gaps 5/10).
5. Catppuccin-Palette + App-Themes nach `shared/`.
6. Raycast-Hotkey auf `alt-shift-enter`.
7. `system.defaults` (nix-darwin): Dark Mode + sinnvolle Basis-Tweaks.

**Ergebnis:** Tiling-WM mit den gewohnten Keybinds, identischer Terminal-/Shell-/Editor-Stack
inkl. Blur, ein `darwin-rebuild switch`.

### Phase 2 — Feinschliff

- `darwin/sketchybar.nix` (Lua, Notch-Layout, `blur_radius`, Catppuccin).
- `darwin/borders.nix` (JankyBorders, Sky→Teal, via AeroSpace-Startup).
- Launcher-Evaluierung Sol vs. Ueli.
- Politur: AeroSpace `exec-on-workspace-change` → SketchyBar-Events, Feinabstimmung Gaps/Optik.

## Validierung

Nach jeder Phase:

- `nix flake check` + `darwin-rebuild build` fehlerfrei.
- **NixOS darf nicht brechen:** nach dem Modul-Split müssen `nixosConfigurations.{desktop,
  laptop,vm}` weiter bauen (`nixos-rebuild build`). Kritisch, weil bestehende Module verschoben
  werden → wird zuerst und isoliert getestet.
- Manuell auf dem Mac: AeroSpace-Keybinds durchgehen, kitty-Blur sichtbar, Themes korrekt.
- Nicht-deklarative Schritte als Checkliste dokumentiert (macOS-Accessibility-Berechtigung für
  AeroSpace, ggf. Homebrew-Casks), nicht versteckt.

## Risiken / offene Punkte

- **Modul-Split darf NixOS-Build nicht brechen** → zuerst und isoliert testen.
- **AeroSpace braucht Accessibility-Berechtigung** (einmalig manuell, nicht deklarierbar).
- **Sol/Ueli evtl. nicht in nixpkgs** → ggf. via nix-darwin `homebrew.casks`, dokumentiert.
- **Hostname des Macs** für `darwinConfigurations.<host>` noch festzulegen (Implementierung).
