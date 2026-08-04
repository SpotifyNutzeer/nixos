# Spicetify replaces Tidal

Date: 2026-08-04

## Goal

Add Spotify with Spicetify to the flake, configured declaratively the same way
Vencord is (flake input -> home-manager module -> plugin list in the Nix config).
Remove Tidal completely from every host and swap the Hyprland autostart.

## Non-goals

- No Spotify replacement for the RodeCaster MIDI bridge or the StreamController
  Tidal plugin. Both are Tidal-specific and get deleted, not ported.
- No renaming of the `sink_tidal_combined` PipeWire sink. The sink is defined in
  the separate `dotfiles` repo and stays as it is; only the routing rule that
  points an application at it changes.

## Approach

`github:Gerg-L/spicetify-nix` is the Vencord/nixcord analogue: it exposes
`homeManagerModules.spicetify` plus a `legacyPackages.<system>` set holding
`extensions`, `apps`, `themes` and `snippets`, so plugins are selected as Nix
attributes instead of imperative `spicetify config` calls. The module installs a
Spicetify-patched Spotify itself — `pkgs.spotify` must not be installed
anywhere else.

The module is shared between NixOS and nix-darwin (`home/program-configs/shared/`)
so both machines get the identical plugin set and theme. `nixpkgs.spotify` lists
`aarch64-darwin` in `meta.platforms` and `spicetifyBuilder.nix` handles the
`Spotify.app/Contents/Resources` layout, so the darwin path is supported
upstream.

## New file: `home/program-configs/shared/spicetify.nix`

```nix
{ pkgs, lib, spicetify-nix, ... }:
let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ spicetify-nix.homeManagerModules.spicetify ];

  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    enabledExtensions = with spicePkgs.extensions; [
      shuffle
      playNext
      volumePercentage
      beautifulLyrics
      coverAmbience
      powerBar
      madeForYouShortcut
      oneko
      history
      songStats
    ];

    enabledCustomApps = with spicePkgs.apps; [ lyricsPlus newReleases ];

    enabledSnippets = [ /* teal accent, see below */ ];
  }
  # `wayland` only exists in the Linux submodule (modules/linuxOpts.nix).
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { wayland = true; };
}
```

`wayland = true` makes the wrapper pass
`--enable-features=UseOzonePlatform --ozone-platform=wayland`, matching how
Discord is forced to native Wayland in `linux/vencord.nix`. The session sets no
`NIXOS_OZONE_WL`, so the option cannot be left at `null`.

### Teal accent

The Catppuccin Spicetify theme has no declarative accent option. `theme.js`
stores the choice in `localStorage["catppuccin-accentColor"]` and applies it as
two *inline* custom properties on `documentElement`:

```js
"--spice-text": `var(--spice-${selectedValue})`,
"--spice-button-active": `var(--spice-${selectedValue})`,
```

With the default value `"none"` it calls `removeProperty` on both, so a snippet
in `user.css` sets the same two variables without an inline style fighting it —
and picking an accent in the settings dropdown later still wins, because inline
styles outrank the stylesheet.

```css
:root {
  --spice-text: var(--spice-teal);
  --spice-button-active: var(--spice-teal);
}
```

Known gap: `--spice-equalizer` points at a per-accent GIF asset
(`equalizer-animated-<accent>.gif`), not a color, so the animated equalizer in
the playbar keeps its default variant. Cosmetic only.

## Tidal removal

| File | Change |
| --- | --- |
| `flake.nix` | Add `spicetify-nix` input with `inputs.nixpkgs.follows = "nixpkgs"`. Drop the `tidaluna`, `rodecaster-tidal-bridge` and `streamcontroller-tidal` inputs, the `tidaluna` overlay and `streamcontrollerOverlay`. Pass `spicetify-nix` through both `home-manager.extraSpecialArgs` sets. |
| `common/programs.nix` | Remove the `tidal-hifi` symlinkJoin wrapper and its `environment.systemPackages` entry. |
| `common/sddm.nix` | Keep `gnome-keyring` — Brave and seadrive-gui use the same secret service. Only rewrite the two comments that justify it via tidal-hifi. |
| `home/program-configs/linux/hyprland.nix` | `exec-once`: `uwsm app -- tidal-hifi` -> `uwsm app -- spotify`. Keep the `systemctl --user start pipewire-pulse.service` warm start and rewrite its comment for Spotify — Spotify is Chromium-based and hits the identical PulseAudio cold-start / ALSA-fallback race. Window rule `^tidal-hifi$` -> `^spotify$`. |
| `home/program-configs/linux/xdg-mime.nix` | `x-scheme-handler/tidaLuna` -> `x-scheme-handler/spotify` = `spotify.desktop`. |
| `hosts/desktop/pipewire.nix` | Rename the drop-in to `50-spotify-target.conf` and match `application.process.binary = "~.*[Ss]potify.*"`. The regex form is deliberate: `spicetifyBuilder.nix` uses `wrapProgramShell`, so the running binary may be `.spotify-wrapped`. Target sink stays `sink_tidal_combined`. |
| `hosts/desktop/rodecaster-tidal-bridge.nix` | Delete the file and its import in `hosts/desktop/default.nix`. |
| `hosts/desktop/streamcontroller.nix` | Drop the `wtf_paul_TidalController` plugin link. StreamController itself and its udev rules stay. |
| `hosts/macbook/default.nix` | Remove TIDAL.app and the `tidaluna` module argument; `environment.systemPackages` disappears entirely. |
| `home/home-linux.nix`, `home/home-darwin.nix` | Import `./program-configs/shared/spicetify.nix`. |

## Verification

1. `nix flake check` / `nix eval .#nixosConfigurations.desktop.config.system.build.toplevel` builds.
2. `nixos-rebuild` on the desktop, `darwin-rebuild` on the MacBook.
3. Spotify starts on workspace 2, theme is Catppuccin Mocha, accent text/buttons
   are teal.
4. `hyprctl clients` reports class `spotify` (confirms the window rule matches).
5. `pactl list clients | grep -i binary` shows the actual process binary; confirm
   the PipeWire regex matches and Spotify lands on `sink_tidal_combined`.
6. `grep -ri tidal` over the repo returns nothing but flake.lock history.
