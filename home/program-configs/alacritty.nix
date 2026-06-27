{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings.window = {
      opacity = 0.8;
      decorations = "Full";
    };
    settings.font.size = 11.0;

    settings.font.normal      = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
    settings.font.bold        = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
    settings.font.italic      = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
    settings.font.bold_italic = { family = "JetBrainsMono Nerd Font"; style = "Bold Italic"; };
    
    settings.scrolling                   = { history = 50000; multiplier = 3; };
    settings.selection.save_to_clipboard = true;
    settings.mouse.hide_when_typing      = true;
    
    settings.keyboard.bindings = [
      {
        key = "Return";
        mods = "Shift";
        chars = "\u001B\r";
      }
    ];

  };
}
