{ catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";

    cursors.enable = true;
  
    hyprland.enable = false;
  };

  home.pointerCursor = {
    gtk.enable = true;
    size = 24;
  };
}
