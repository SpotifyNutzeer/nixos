{ pkgs, tidaluna, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    kitty
    alacritty
    firefox
    claude-code
    tidaluna.packages.${stdenv.hostPlatform.system}.default 
    pavucontrol
    grimblast
    fastfetch
    vencord
  ];
  programs.fish.enable = true;
  programs.nano.enable = false;
  programs.git = {
    enable = true;
    config.user.name = "Paul Reitmayer";
    config.user.email = "paul.reitmayer@pm.me";
  };
}
