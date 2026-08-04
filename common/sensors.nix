{ pkgs, ... }:
{
  # RAPL energy_uj has been root-only since the Platypus vulnerability. Make it
  # readable again via udev for the quickshell CPU power display (desktop +
  # laptop).
  services.udev.extraRules = ''
    SUBSYSTEM=="powercap", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys%p/energy_uj"
  '';
}
