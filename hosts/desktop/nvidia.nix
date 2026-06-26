{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = false;
  };
}

