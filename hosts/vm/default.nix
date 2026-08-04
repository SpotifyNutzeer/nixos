{ ... }:
{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./boot.nix
  ];

  networking.hostName = "nixos";
  # SPICE guest agent (clipboard sharing, display resize) — only useful
  # inside the QEMU/SPICE guest, hence here and not in common/.
  services.spice-vdagentd.enable = true;
  system.stateVersion = "26.05";
}
