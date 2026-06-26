{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      # tuigreet authentifiziert auf der TTY und startet danach den Befehl als dein User.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd start-hyprland";
      user = "greeter";
    };
  };
}
