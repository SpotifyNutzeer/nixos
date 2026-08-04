{ ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
        font_family      = "JetBrainsMono Nerd Font";
        bold_font        = "auto";
        italic_font      = "auto";
        bold_italic_font = "auto";
        font_size        = 11;

        background_opacity = 0.80;
        # On macOS kitty renders the blur itself (native API), independent of the
        # compositor. There the value is also the blur radius; uncritical up to ~64.
        # Under Hyprland the compositor handles the blur — the same line does no harm.
        background_blur    = 32;

        # No window decorations (titlebar/traffic-light buttons) — fits the tiling WM.
        # On Hyprland there is no client-side titlebar anyway, so this is harmless.
        hide_window_decorations = "yes";

        # macOS: quit the app when the last window closes — otherwise a
        # windowless Dock icon is left behind. No effect on Linux.
        macos_quit_when_last_window_closed = "yes";

        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        cursor_trail_start_threshold = 0; 
    };

    # macOS: skhd passes alt+shift+q through to kitty (yabai cannot close
    # windows without a close button), kitty closes the OS window itself.
    # Harmless under Hyprland — there the compositor intercepts SUPER+SHIFT+Q.
    keybindings = {
      "alt+shift+q" = "close_os_window";
    };
  };
}
