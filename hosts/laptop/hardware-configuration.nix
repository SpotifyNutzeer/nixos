# Platzhalter — wird bei der Installation von nixos-anywhere via
# --generate-hardware-config durch die echte Konfiguration ersetzt.
# Dauerhafte Hardware-Einstellungen (Microcode, Firmware) liegen deshalb
# in boot.nix, damit sie das Ueberschreiben ueberleben.
{ ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
