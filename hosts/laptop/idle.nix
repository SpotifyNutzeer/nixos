{ ... }:
{
  # Idle-Management fuer den Laptop (home-manager-User-Service, nur hier
  # importiert). Deckt auch das Zuklappen ab: Der Deckel loest per logind-Default
  # Suspend aus, und before_sleep_cmd sperrt VOR dem Suspend -> nach dem
  # Aufklappen ist der Bildschirm gesperrt und verlangt das Passwort.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd       = "pidof hyprlock || hyprlock";  # keine doppelten Instanzen
        before_sleep_cmd = "loginctl lock-session";      # vor Suspend/Deckel-zu sperren
        after_sleep_cmd  = "hyprctl dispatch dpms on";    # Display nach Resume wieder an
      };

      listener = [
        # 5 min: Bildschirm dimmen (vorher Helligkeit merken)
        {
          timeout   = 300;
          on-timeout = "brightnessctl -s set 10%";
          on-resume  = "brightnessctl -r";
        }
        # 10 min: sperren
        {
          timeout   = 600;
          on-timeout = "loginctl lock-session";
        }
        # ~10,5 min: Display aus
        {
          timeout   = 630;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume  = "hyprctl dispatch dpms on";
        }
        # 30 min: Suspend (before_sleep_cmd sperrt bereits davor)
        {
          timeout   = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
