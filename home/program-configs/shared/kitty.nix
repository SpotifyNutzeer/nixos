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

        background_opacity = 0.80;
        # Auf macOS rendert kitty den Blur selbst (native API), unabhaengig vom
        # Compositor. Der Wert ist dort zugleich der Blur-Radius; bis ~64 unkritisch.
        # Unter Hyprland uebernimmt den Blur der Compositor — dieselbe Zeile schadet nicht.
        background_blur    = 32;

        # Keine Fenster-Dekoration (Titlebar/Ampel-Buttons) — passt zum Tiling-WM.
        # Auf Hyprland ohnehin ohne clientseitige Titlebar, daher unschaedlich.
        hide_window_decorations = "yes";

        # macOS: App beenden, wenn das letzte Fenster schliesst — sonst bleibt
        # ein fensterloses Dock-Icon zurueck. Unter Linux wirkungslos.
        macos_quit_when_last_window_closed = "yes";

        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        cursor_trail_start_threshold = 0; 
    };

    # macOS: skhd reicht alt+shift+q fuer kitty durch (yabai kann Fenster ohne
    # Close-Button nicht schliessen), kitty schliesst das OS-Fenster selbst.
    # Unter Hyprland harmlos — dort faengt SUPER+SHIFT+Q der Compositor ab.
    keybindings = {
      "alt+shift+q" = "close_os_window";
    };
  };
}
