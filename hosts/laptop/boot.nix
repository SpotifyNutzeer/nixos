{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # amdgpu schon im Initrd laden (early KMS): LUKS-Prompt in nativer
  # Aufloesung statt simpledrm/efifb.
  boot.initrd.kernelModules = [ "amdgpu" ];

  # systemd-initrd wendet console.keyMap ("de", common/locale.nix) schon
  # VOR der LUKS-Passphrase-Abfrage an — scripted initrd kann das nicht.
  boot.initrd.systemd.enable = true;

  # Hibernate: Resume aus dem Swap-LV im LUKS-Container (siehe disko.nix).
  boot.resumeDevice = "/dev/vg0/swap";

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;   # u.a. WLAN-Firmware (RTL8852CE)
}
