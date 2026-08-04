{ ... }:
{
  # hyprlock authenticates via PAM and needs its own PAM service for that.
  # Without it, the hyprlock installed by home-manager CANNOT unlock the
  # screen (every input fails). The actual lockscreen configuration lives in
  # home/program-configs/linux/hyprlock.nix.
  security.pam.services.hyprlock = { };
}
