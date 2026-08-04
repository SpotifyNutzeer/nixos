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

  # AMD microcode updates and redistributable firmware (incl. the RTL8852CE
  # wifi firmware) are already enabled via hardware-configuration.nix
  # (not-detected.nix sets enableRedistributableFirmware, which in turn
  # drives updateMicrocode there).
}
