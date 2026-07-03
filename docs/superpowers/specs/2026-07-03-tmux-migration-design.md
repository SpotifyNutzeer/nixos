# Design: tmux-Config-Migration von dotfiles nach NixOS/Home-Manager

**Datum:** 2026-07-03
**Status:** Entwurf zur Review

## Ziel

Die tmux-Konfiguration aus `~/git/dotfiles/.config/tmux/tmux.conf` voll deklarativ
in die NixOS-Config migrieren — als Home-Manager-Modul nach dem bestehenden Muster
(`home/program-configs/<programm>.nix`). TPM (Tmux Plugin Manager) und der
imperative `git clone` zur Laufzeit entfallen ersatzlos.

## Ausgangslage

Die bestehende tmux.conf enthält:

- TPM-Bootstrap (git clone beim ersten Start)
- Plugins: `tmux-plugins/tpm`, `tmux-plugins/tmux-sensible`, `catppuccin/tmux#v2.1.3`
- Basis-Settings: mouse, 50k history, vi-Keys, `tmux-256color`, kitty-Truecolor-Override, Reload-Bind
- Catppuccin Mocha/Teal Powerline-Statusbar: `@catppuccin_*`-Optionen **vor** dem
  Plugin-Load, Statusbar-Zusammensetzung mit `set -gF` und `@thm_*`-Farben **nach**
  dem Plugin-Load (die `@thm_*`-Variablen existieren erst nach `run`)

Das NixOS-Repo nutzt bereits die catppuccin/nix-Flake mit `catppuccin.autoEnable = true`
(`home/program-configs/theming.nix`), `flavor = "mocha"`, `accent = "teal"`.

## Versionskompatibilität (verifiziert)

catppuccin/nix (Pin `f2c7dd1`) liefert catppuccin/tmux **v2.3.0** (rev `d2d25bd`)
statt des bisherigen Pins v2.1.3. Diff-Analyse beider Stände:

- Changelog v2.1.3 → v2.3.0 ist rein additiv (Reset-Option, RAM-Modul, kube-Fix, Doku).
- Alle in der Config genutzten Modul-Optionen (`_text`, `_icon`, `_color`,
  `@catppuccin_status_<modul>`) werden dynamisch konstruiert; `status/*.conf` und
  `utils/status_module.conf` sind zwischen beiden Versionen byte-identisch.
- `@catppuccin_window_status_style`, `@catppuccin_window_current_background`,
  Separator- und Fill-Optionen existieren unverändert.

**Ergebnis:** Die Config ist ohne Anpassung mit v2.3.0 kompatibel; kein Pinning nötig.

## Architektur

Neue Datei `home/program-configs/tmux.nix`, Import in `home/home.nix`.

### Abbildung der Config-Teile

| tmux.conf-Teil | Ziel |
|---|---|
| TPM-Bootstrap + `run tpm` | entfällt |
| Plugin `tmux-sensible` | `programs.tmux.sensibleOnTop = true` |
| Plugin `catppuccin/tmux` | automatisch via `catppuccin.autoEnable` sobald `programs.tmux.enable = true`; setzt auch `@catppuccin_flavor 'mocha'` |
| `mouse on` | `programs.tmux.mouse = true` |
| `history-limit 50000` | `programs.tmux.historyLimit = 50000` |
| `mode-keys vi` | `programs.tmux.keyMode = "vi"` |
| `default-terminal "tmux-256color"` | `programs.tmux.terminal = "tmux-256color"` |
| kitty-Truecolor-Override, Reload-Bind | `programs.tmux.extraConfig` |
| `@catppuccin_*`-Optionen (vor Plugin-Load) | `catppuccin.tmux.extraConfig` |
| Statusbar-Zusammensetzung (`set -gF`, `status-left`/`-right`; nach Plugin-Load) | `programs.tmux.extraConfig` |

### Lade-Reihenfolge (im gepinnten Home-Manager verifiziert)

Das HM-tmux-Modul generiert `~/.config/tmux/tmux.conf` in dieser Reihenfolge:

1. `mkBefore`: HM-Optionen (mouse, keyMode, …) inkl. sensible-Plugin am Anfang
2. Plugin-Sektion: pro Plugin erst dessen `extraConfig`, dann `run-shell` —
   `catppuccin.tmux.extraConfig` landet damit **vor** dem Plugin-Load ✓
3. `mkAfter`: `programs.tmux.extraConfig` — landet **nach** dem Plugin-Load ✓

Damit bleibt die semantische Struktur der Original-Config exakt erhalten.

### Randnotizen

- Der Reload-Bind (`bind r source-file ~/.config/tmux/tmux.conf`) funktioniert
  weiter, da HM die Datei an denselben Pfad symlinkt.
- Die dotfiles bleiben unangetastet (separates Repo; Aufräumen dort ist nicht
  Teil dieser Migration).

## Fehlerbehandlung

Keine Laufzeit-Fehlerpfade — die Migration ist rein deklarativ. Fehler zeigen sich
beim Build (`nix flake check` / `nixos-rebuild build`) oder visuell in der Statusbar.

## Verifikation

1. Build der Systemkonfiguration (`nixos-rebuild build --flake .#<host>` bzw. Eval
   der Home-Config).
2. Generierte `tmux.conf` im Store inspizieren: Reihenfolge (Optionen → catppuccin-
   extraConfig → run-shell → Statusbar-Block) und Vollständigkeit aller Settings
   gegen die Original-Config prüfen.
3. Nach dem Switch: tmux starten, Statusbar (Mocha/Teal-Powerline, Module Session/
   Application/Directory/Host/DateTime) und Basis-Verhalten (Mouse, vi-Copy-Mode,
   Truecolor in kitty) prüfen.
