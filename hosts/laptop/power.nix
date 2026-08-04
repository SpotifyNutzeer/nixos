{ pkgs, ... }:
{
  # TLP for battery runtime; the defaults are enough for a start.
  services.tlp.enable = true;
  # power-profiles-daemon conflicts with TLP.
  services.power-profiles-daemon.enable = false;

  # Brightness keys: the binds (XF86MonBrightness*) already exist in the
  # shared Hyprland config, only the tool is missing.
  environment.systemPackages = [ pkgs.brightnessctl ];
}
