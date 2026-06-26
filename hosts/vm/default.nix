{ ... }:
{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./boot.nix
  ];

  networking.hostName = "nixos";
  system.stateVersion = "26.05";
}
