{ ... }:
{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./boot.nix
    ./nvidia.nix
    ../../common/sddm.nix
    ./audio.nix
    ./gaming.nix
    ./coolercontrol.nix
    ./lact.nix
    ./streamcontroller.nix
  ];

  home-manager.users.paul.imports =
    [
      ./pipewire.nix
      ./fosi-keepalive.nix
      ./rodecaster-tidal-bridge.nix
      ./mangohud.nix
      ./hyprland-monitors.nix
    ];
  networking.hostName = "paul-desktop";
  system.stateVersion = "26.05";
}
