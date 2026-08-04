{ pkgs, lib, spicetify-nix, ... }:
let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ spicetify-nix.homeManagerModules.spicetify ];

  # The module builds a Spicetify-patched Spotify and installs it into
  # home.packages itself -- pkgs.spotify must NOT be added anywhere else,
  # otherwise two Spotify binaries end up in PATH.
  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    # The Catppuccin theme has no declarative accent option: theme.js keeps the
    # choice in localStorage ("catppuccin-accentColor") and applies it as two
    # INLINE custom properties. With the default "none" it calls removeProperty
    # on both, so this snippet can set teal from user.css. Picking an accent in
    # Spotify's settings later still wins (inline styles outrank the sheet).
    # Not covered: --spice-equalizer points at a per-accent GIF asset rather
    # than a color, so the playbar equalizer keeps its default variant.
    enabledSnippets = [
      ''
        :root {
          --spice-text: var(--spice-teal);
          --spice-button-active: var(--spice-teal);
        }
      ''
    ];

    enabledExtensions = with spicePkgs.extensions; [
      shuffle           # real Fisher-Yates instead of Spotify's biased shuffle
      playNext          # add a track to the TOP of the queue
      volumePercentage  # percentage next to the slider + finer volume steps
      beautifulLyrics   # word-by-word/karaoke synced lyrics
      coverAmbience     # glow derived from the current album cover
      powerBar          # Spotlight-style search bar
      madeForYouShortcut
      oneko             # cat follows the mouse
      history           # listening history page
      songStats         # tempo, key, danceability
    ];

    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus        # scrolling lyrics page, also feeds fullscreen display
      newReleases
    ];
  }
  # `wayland` only exists in the Linux submodule (modules/linuxOpts.nix), so it
  # cannot be set unconditionally. true forces the ozone Wayland flags, same as
  # Discord in linux/vencord.nix; leaving it null would rely on NIXOS_OZONE_WL,
  # which the uwsm session environment does not set.
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { wayland = true; };
}
