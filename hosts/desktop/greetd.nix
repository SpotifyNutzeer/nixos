{ pkgs, ... }:
{
  # Grafischer Wayland-Greeter: ReGreet laeuft unter cage (Kiosk-Compositor).
  # programs.regreet verdrahtet greetd selbst (setzt default_session auf
  # "dbus-run-session cage -s -d -- regreet"), zieht cage + regreet + GTK-Theme rein.
  programs.regreet.enable = true;

  systemd.services.greetd.environment.XKB_DEFAULT_LAYOUT = "de";
  # greetd legt den unprivilegierten Greeter-User an; regreet liest ihn hier aus.
  services.greetd.settings.default_session.user = "greeter";
  programs.regreet.font = {
    package = pkgs.dejavu_fonts;
    name = "DejaVu Sans";
  };
}
