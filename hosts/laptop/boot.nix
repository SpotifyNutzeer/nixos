{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Load amdgpu already in the initrd (early KMS): LUKS prompt in native
  # resolution instead of simpledrm/efifb.
  boot.initrd.kernelModules = [ "amdgpu" ];

  # systemd-initrd applies console.keyMap ("de", common/locale.nix) already
  # BEFORE the LUKS passphrase prompt — scripted initrd cannot do that.
  boot.initrd.systemd.enable = true;

  # Hibernate: resume from the swap LV inside the LUKS container (see disko.nix).
  boot.resumeDevice = "/dev/vg0/swap";

  # AMD microcode updates and redistributable firmware (incl. the RTL8852CE
  # wifi firmware) are already enabled via hardware-configuration.nix
  # (not-detected.nix sets enableRedistributableFirmware, which in turn
  # drives updateMicrocode there).
}
