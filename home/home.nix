{ pkgs, ... }:
{
  imports = 
    [
      ./program-configs/starship.nix
      ./program-configs/fish.nix
      ./program-configs/vim.nix
      ./program-configs/hyprland.nix
      ./program-configs/quickshell.nix
      ./program-configs/vencord.nix
      ./program-configs/brave.nix
    ];  
  home.username = "paul";
  home.homeDirectory = "/home/paul";
  home.stateVersion = "26.05";
}
