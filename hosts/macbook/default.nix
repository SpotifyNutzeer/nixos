{ pkgs, tidaluna, ... }:
{
  imports = [ ./yabai.nix ./homebrew.nix ./sudo-askpass.nix ];

  # Terminal/UI font for the whole system (kitty, sketchybar-style tooling).
  # Used to live in sketchybar.nix; the bar itself was removed (disabled
  # since 2026-07-06, see git history if it should ever come back).
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "paul-macbook";

  # nix-darwin verlangt fuer user-bezogene Optionen (homebrew, defaults) einen Primaeruser.
  system.primaryUser = "paulweber";
  users.users.paulweber.home = "/Users/paulweber";

  # Nix wird von Determinate Nix (eigener Daemon) verwaltet — nix-darwin darf
  # die Nix-Installation NICHT ebenfalls verwalten, sonst bricht die Aktivierung
  # ("Determinate detected, aborting activation"). Flakes/nix-command sind bei
  # Determinate ohnehin global aktiv, daher entfaellt hier nix.settings.
  nix.enable = false;

  # fish ist Login-Shell -> nix-darwin muss die System-Integration einrichten
  # (/etc/fish + fish in /etc/shells + System-PATH), sonst hat die fish-Login-Shell
  # weder nix- noch sonstige System-Pfade. (common/ mit demselben Flag ist NixOS-only.)
  programs.fish.enable = true;

  # home-shared.nix (programs.vim) zieht unfreie vim-Plugins (asyncomplete-buffer-vim).
  # Auf NixOS setzt common/programs.nix dies system-weit; darwin braucht das
  # Aequivalent, sonst schlaegt die Home-Manager-Evaluierung (useGlobalPkgs) fehl.
  nixpkgs.config.allowUnfree = true;

  # Offizielle TIDAL.app (aarch64-darwin, unfree) mit injiziertem TidaLuna.
  # Wie auf Linux (common/programs.nix) direkt aus der TidaLuna-Flake, die
  # ihren EIGENEN nixpkgs-Pin mitbringt — der Overlay-Weg wuerde stattdessen
  # mit unserem nixos-unstable bauen, dessen fetchPnpmDeps das von TidaLuna
  # genutzte fetcherVersion=3 nicht mehr unterstuetzt. Der Linux-Wrapper
  # (--password-store=gnome-libsecret) entfaellt hier: Electrons safeStorage
  # nutzt auf macOS automatisch den Keychain.
  environment.systemPackages = [
    tidaluna.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Systemweit Dark Mode.
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # nix-darwin-Schema-Version. Falls darwin-rebuild einen anderen Wert erwartet,
  # meldet es das explizit — dann hier anpassen.
  system.stateVersion = 5;
}
