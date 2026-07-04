{ ... }:
{
  # hyprlock authentifiziert ueber PAM und braucht dafuer einen eigenen
  # PAM-Service. Ohne diesen kann der von home-manager installierte hyprlock
  # den Bildschirm NICHT entsperren (jede Eingabe schlaegt fehl). Die eigentliche
  # Lockscreen-Konfiguration liegt in home/program-configs/hyprlock.nix.
  security.pam.services.hyprlock = { };
}
