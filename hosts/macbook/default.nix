{ ... }:
{
  imports = [ ./yabai.nix ./homebrew.nix ./sketchybar.nix ];

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

  # home-shared.nix (programs.vim) zieht unfreie vim-Plugins (asyncomplete-buffer-vim).
  # Auf NixOS setzt common/programs.nix dies system-weit; darwin braucht das
  # Aequivalent, sonst schlaegt die Home-Manager-Evaluierung (useGlobalPkgs) fehl.
  nixpkgs.config.allowUnfree = true;

  # Systemweit Dark Mode.
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # nix-darwin-Schema-Version. Falls darwin-rebuild einen anderen Wert erwartet,
  # meldet es das explizit — dann hier anpassen.
  system.stateVersion = 5;
}
