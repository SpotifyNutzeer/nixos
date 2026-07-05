{ ... }:
{
  programs.kitty = {
    enable = true;
    enableGitIntegration = true;
    settings = {
        font_family      = "JetBrainsMono Nerd Font";
        bold_font        = "auto";
        italic_font      = "auto";
        bold_italic_font = "auto";
        font_size        = 11;

        background_opacity = 0.90;
        # Auf macOS rendert kitty den Blur selbst (native API), unabhaengig vom
        # Compositor. Der Wert ist dort zugleich der Blur-Radius; bis ~64 unkritisch.
        # Unter Hyprland uebernimmt den Blur der Compositor — dieselbe Zeile schadet nicht.
        background_blur    = 32;

        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        cursor_trail_start_threshold = 0; 
    };
  };
}
