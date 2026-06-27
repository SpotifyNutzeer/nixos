{ catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
    hyprland.enable = false;
  };
}
