{ ... }:
{
  imports = [
    ../../common
    ../../common/sddm.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./boot.nix
    ./power.nix
  ];

  home-manager.users.paul.imports = [ ./hyprland-monitors.nix ];

  networking.hostName = "paul-laptop";
  system.stateVersion = "26.05";
}
