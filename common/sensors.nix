{ pkgs, ... }:
{
  # RAPL-energy_uj ist seit der Platypus-Luecke root-only. Fuer die quickshell-
  # CPU-Power-Anzeige per udev wieder lesbar machen (Desktop + Laptop).
  services.udev.extraRules = ''
    SUBSYSTEM=="powercap", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys%p/energy_uj"
  '';
}
