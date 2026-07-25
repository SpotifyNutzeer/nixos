# Fish-Startup-Übersicht (hyfetch, teal-sky)

Datum: 2026-07-25 · Status: approved

## Ziel

Beim Öffnen eines neuen Terminal-Fensters zeigt Fish eine System-Übersicht via
hyfetch (fastfetch-Backend), deren Info-Spalte farblich zum Starship-Powerline-
Schema passt (Catppuccin Mocha, teal `#94e2d5` / sky `#89dceb`).

## Design

### 1. Fastfetch-Config (`home/program-configs/shared/fastfetch.nix`, neu)

- `programs.fastfetch.enable = true` + `settings` → `~/.config/fastfetch/config.jsonc`,
  genau dort liest das hyfetch-Backend die Modul-Config; hyfetch liefert weiterhin
  das Logo (Preset `gay-men`).
- Module: title, separator, OS, Kernel, Uptime, Packages, Shell, WM, CPU, Memory,
  Disk, Farbpalette.
- Icon-Keys (Nerd Font), Keyfarben gruppiert: System-Block in teal, Hardware-Block
  in sky; Titel user in teal / host in sky, Separator gedimmt (overlay0 `#6c7086`).
- Import in `home/home-shared.nix` (gilt für Linux + macOS).
- Aufräumen: manuelles `home.packages = [ pkgs.fastfetch ]` in
  `home/program-configs/darwin/hyfetch.nix` entfernen — `programs.fastfetch.enable`
  installiert das Binary auf beiden Plattformen.

### 2. Greeting-Logik (`home/program-configs/shared/fish.nix`)

- `fish_greeting` leeren; in `interactiveShellInit`:
  hyfetch nur ausführen, wenn `__greeting_shown` nicht gesetzt ist, danach
  `set -gx __greeting_shown 1` — nested Shells und tmux-Splits erben die Variable
  und bleiben ruhig, jedes neue Terminal-Fenster zeigt die Übersicht.
- Fehlerfall: `command -q hyfetch; and hyfetch` — fehlt das Binary, gibt es
  schlicht kein Greeting statt einer Fehlermeldung.

## Verifikation

- Eval/Build der Flake-Konfigurationen (Linux + darwin) schlägt nicht fehl.
- Neues Terminal zeigt hyfetch-Logo + teal-sky-Info-Spalte; `fish` in einer
  laufenden Shell zeigt kein zweites Greeting.
