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
        cursor_trail = 3000;
        cursor_trail_decay = "0.1 0.4";
        
    }
  }
}