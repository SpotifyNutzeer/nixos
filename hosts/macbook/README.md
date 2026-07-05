# macbook (nix-darwin)

## Erst-Setup
1. `sudo nix run nix-darwin -- switch --flake .#macbook`
2. Bedienungshilfen-Berechtigung für **AeroSpace** erteilen
   (Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen).
3. Danach normal: `darwin-rebuild switch --flake .#macbook`

## Manuelle / nicht-deklarative Punkte
- AeroSpace-Accessibility-Berechtigung (einmalig, macOS-Sicherheit).
- Launcher: im MVP Raycast (Hotkey `alt-shift-enter` via AeroSpace). Phase 2: Sol/Ueli.
- Brave & GUI-Casks: Phase 2 via homebrew.

## Phase 2 (offen)
SketchyBar (Notch-Layout), JankyBorders (Sky→Teal), Sol/Ueli-Launcher, Brave via homebrew.
