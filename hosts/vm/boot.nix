{ pkgs, ... }:
{
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
  };
  
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
