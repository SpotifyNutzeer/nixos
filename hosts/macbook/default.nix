{ pkgs, ... }:
{
  imports = [ ./yabai.nix ./homebrew.nix ./sudo-askpass.nix ];

  # Terminal/UI font for the whole system (kitty, sketchybar-style tooling).
  # Used to live in sketchybar.nix; the bar itself was removed (disabled
  # since 2026-07-06, see git history if it should ever come back).
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "paul-macbook";

  # nix-darwin requires a primary user for user-scoped options (homebrew, defaults).
  system.primaryUser = "paulweber";
  users.users.paulweber.home = "/Users/paulweber";

  # Nix is managed by Determinate Nix (its own daemon) — nix-darwin must NOT
  # manage the Nix installation as well, otherwise activation breaks
  # ("Determinate detected, aborting activation"). Flakes/nix-command are
  # globally enabled with Determinate anyway, so nix.settings is omitted here.
  nix.enable = false;

  # fish is the login shell -> nix-darwin has to set up the system integration
  # (/etc/fish + fish in /etc/shells + system PATH), otherwise the fish login shell
  # has neither nix paths nor any other system paths. (common/ with the same flag
  # is NixOS-only.)
  programs.fish.enable = true;

  # home-shared.nix (programs.vim) pulls in unfree vim plugins (asyncomplete-buffer-vim).
  # On NixOS common/programs.nix sets this system-wide; darwin needs the
  # equivalent, otherwise the Home Manager evaluation (useGlobalPkgs) fails.
  nixpkgs.config.allowUnfree = true;

  # Spotify comes from the shared spicetify module
  # (home/program-configs/shared/spicetify.nix) via home-manager, with the same
  # extensions and Catppuccin theme as on the desktop.

  # System-wide dark mode.
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # nix-darwin schema version. Note: darwin-rebuild only errors when
  # stateVersion is unset or outside the supported range — an outdated value is
  # accepted silently, so any bump has to be a deliberate manual change here.
  system.stateVersion = 5;
}
