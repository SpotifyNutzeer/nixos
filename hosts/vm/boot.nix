{ pkgs, ... }:
{
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
