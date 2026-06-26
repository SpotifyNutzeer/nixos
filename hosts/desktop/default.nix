{ ... }:
{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./boot.nix
    ./nvidia.nix
    ./greetd.nix
    ./sensors.nix
  ];

  networking.hostName = "paul-desktop";
  system.stateVersion = "26.05";
}
