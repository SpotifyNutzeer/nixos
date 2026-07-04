{ pkgs, ... }:
{
  imports = 
    [
      ./program-configs/starship.nix
      ./program-configs/fish.nix
      ./program-configs/vim.nix
      ./program-configs/hyprland.nix
      ./program-configs/quickshell.nix
      ./program-configs/hyprlock.nix
      ./program-configs/claude-code.nix
      ./program-configs/vencord.nix
      ./program-configs/brave.nix
      ./program-configs/theming.nix
      ./program-configs/alacritty.nix
      ./program-configs/rofi.nix
      ./program-configs/hyfetch.nix
      ./program-configs/kitty.nix
      ./program-configs/tmux.nix
      ./program-configs/xdg-mime.nix
      ./program-configs/ssh.nix
    ];
  home.username = "paul";
  home.homeDirectory = "/home/paul";
  home.stateVersion = "26.05";
}
