{ pkgs, ... }:
{
  # TLP fuer Akku-Laufzeit; Defaults reichen fuer den Anfang.
  services.tlp.enable = true;
  # power-profiles-daemon kollidiert mit TLP.
  services.power-profiles-daemon.enable = false;

  # Helligkeitstasten: die Binds (XF86MonBrightness*) existieren bereits
  # in der geteilten Hyprland-Config, es fehlt nur das Tool.
  environment.systemPackages = [ pkgs.brightnessctl ];
}
