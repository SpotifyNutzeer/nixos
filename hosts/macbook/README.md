# macbook (nix-darwin)

## Window-Manager: yabai + skhd (BSP = dwindle)

WM ist **yabai** (echtes Binary-Space-Partitioning, entspricht Hyprlands dwindle) mit
**skhd** als Hotkey-Daemon und **JankyBorders** für den Fensterrahmen. AeroSpace liegt
noch als Backup unter `home/program-configs/darwin/aerospace.nix`, ist aber NICHT
importiert (zwei WMs kollidieren) — wird gelöscht, sobald yabai stabil läuft.

## Erst-Setup (Reihenfolge wichtig!)

1. **SIP partiell deaktivieren** (nötig für yabais Scripting Addition = Space-Steuerung):
   - Neustart in recoveryOS: Mac ausschalten, dann Power-Taste gedrückt halten bis
     „Startoptionen werden geladen" erscheint → **Optionen** → Terminal öffnen.
   - Dort ausführen: `csrutil enable --without fs --without debug --without nvram`
     (yabais empfohlene Teil-Deaktivierung; NICHT komplett `csrutil disable`).
   - Neu starten.
2. `darwin-rebuild switch --flake .#macbook` (bzw. beim allerersten Mal
   `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook`).
3. **Bedienungshilfen-Berechtigung** erteilen für **yabai** UND **skhd**
   (Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen).
4. yabai/skhd neu starten lassen (`yabai --restart-service`, `skhd --restart-service`)
   oder ab-/anmelden. Die 10 Spaces werden beim yabai-Start automatisch angelegt.

## Nach macOS-Updates

Ein macOS-Update kann die Scripting Addition entladen. Dann einmalig:
`sudo yabai --load-sa` (läuft dank nix-darwin passwordlos) oder yabai neu starten.
Selten macht ein größeres Update auch den SIP-Teil-Disable rückgängig → Schritt 1
wiederholen.

## Manuelle / nicht-deklarative Punkte
- SIP-Partial-Disable (recoveryOS, Sicherheitsgrenze — nicht automatisierbar).
- Accessibility-Berechtigung für yabai + skhd (einmalig).
- Launcher: **Raycast** (Hotkey `alt+shift-return` via skhd → `open raycast://`).
  Nicht deklarierbar (Raycast-Config ist GUI/Cloud). Sol/Ueli wurden erwogen:
  Ueli ist deprecated (Gatekeeper), Sol wäre die Alternative — vorerst bei Raycast.

## Keybinds (Modifier = Alt ⌥)
- `alt-return` kitty · `alt+shift-q` close · `alt-f` fullscreen · `alt-v` float
- `alt-j` split-Richtung togglen (dwindle) · `alt-e` Finder · `alt+shift-return` Raycast
- `alt-←/→/↑/↓` Fokus · `alt-1..0` Space 1..10 · `alt+shift-1..0` Fenster → Space
- Maus: `alt`+Linksdrag = move, `alt`+Rechtsdrag = resize

## Troubleshooting

**Border flackert / verschwindet periodisch (~100ms alle paar Sekunden):**
Es läuft eine zweite borders-Instanz (typisch: Homebrew-Leftover aus einem früheren
manuellen yabai-Versuch), die mit dem nix-`org.nixos.jankyborders`-Service kollidiert —
der nix-Service flappt dann (`launchctl print gui/$(id -u)/org.nixos.jankyborders`
zeigt `state = spawn scheduled`, `runs` steigt). Prüfen:
```
launchctl list | grep -iE 'yabai|skhd|border'   # es darf nur org.nixos.* laufen
brew list | grep -iE 'yabai|skhd|borders'        # keine Homebrew-WM-Tools
```
Homebrew-Leftover entfernen: `brew uninstall borders` und
`rm ~/Library/LaunchAgents/homebrew.mxcl.borders.plist`, danach
`launchctl kickstart -k gui/$(id -u)/org.nixos.jankyborders`.
Generell gilt: WM-Stack (yabai/skhd/borders) NUR über nix, nie zusätzlich via Homebrew.

## Noch offen
AeroSpace-Backup (`home/program-configs/darwin/aerospace.nix`) löschen, sobald yabai dauerhaft stabil.
