{ ... }:
{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./boot.nix
    ./nvidia.nix
    ./sddm.nix
    ./sensors.nix
    ./audio.nix
  ];
  
  home-manager.users.paul.imports =
    [
      ./pipewire.nix
      ./fosi-keepalive.nix
      ./rodecaster-tidal-bridge.nix
    ];
  networking.hostName = "paul-desktop";
  system.stateVersion = "26.05";
}
