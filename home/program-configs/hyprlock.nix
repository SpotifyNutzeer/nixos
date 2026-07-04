{ dotfiles, ... }:
{
  # Lockscreen im Catppuccin-Mocha/Teal-Look (manuell gethemet, da es kein
  # catppuccin-hyprlock-Modul gibt). Hintergrund ist das geblurrte System-
  # Wallpaper. Authentifizierung braucht den PAM-Service aus common/hyprlock.nix.
  # Sperren via Super+L (Keybind in hyprland.nix).
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      # ── Hintergrund: geblurrtes Wallpaper, leicht abgedunkelt ────────────────
      background = [{
        path = "${dotfiles}/wallpapers/firewatchcatpuccinmochagreen.png";
        blur_passes = 3;
        blur_size = 8;
        brightness = 0.75;
        contrast = 0.9;
        vibrancy = 0.17;
      }];

      # ── Eingabefeld ──────────────────────────────────────────────────────────
      input-field = [{
        monitor = "";
        size = "300, 54";
        position = "0, -55";
        halign = "center";
        valign = "center";

        outline_thickness = 2;
        rounding = 14;
        dots_size = 0.25;
        dots_spacing = 0.3;
        dots_center = true;
        fade_on_empty = false;

        outer_color = "rgb(94e2d5)";   # teal (Akzent)
        inner_color = "rgb(1e1e2e)";   # base
        font_color  = "rgb(cdd6f4)";   # text
        check_color = "rgb(89b4fa)";   # blue waehrend Pruefung
        fail_color  = "rgb(f38ba8)";   # red bei Fehler

        placeholder_text = "󰌾  Gesperrt";
        fail_text = "󰗠  Falsch ($ATTEMPTS)";

        shadow_passes = 2;
        shadow_size = 4;
      }];

      # ── Labels: Uhr, Datum, Begruessung, Akku (nur Laptop) ───────────────────
      label = [
        # Grosse Uhr
        {
          monitor = "";
          text = ''cmd[update:1000] date +"%H:%M"'';
          font_family = "JetBrainsMono Nerd Font";
          font_size = 112;
          color = "rgb(cdd6f4)";
          position = "0, 190";
          halign = "center";
          valign = "center";
          shadow_passes = 3;
          shadow_size = 8;
          shadow_color = "rgba(0,0,0,0.6)";
        }
        # Datum
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %-d. %B"'';
          font_family = "JetBrainsMono Nerd Font";
          font_size = 20;
          color = "rgb(a6adc8)";
          position = "0, 95";
          halign = "center";
          valign = "center";
        }
        # Begruessung
        {
          monitor = "";
          text = "Willkommen zurück, Paul";
          font_family = "JetBrainsMono Nerd Font";
          font_size = 15;
          color = "rgb(94e2d5)";
          position = "0, 25";
          halign = "center";
          valign = "center";
        }
        # Akku – nur wenn BAT0 existiert (auf dem Desktop leer -> unsichtbar)
        {
          monitor = "";
          text = ''cmd[update:5000] cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null); [ -n "$cap" ] && echo "󰁹  $cap%"'';
          font_family = "JetBrainsMono Nerd Font";
          font_size = 15;
          color = "rgb(a6adc8)";
          position = "0, 55";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
