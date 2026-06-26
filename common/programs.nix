{ pkgs, ... }:
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
    tidal-hifi
  ];
  programs.fish.enable = true;
  programs.nano.enable = false;
  programs.git = {
    enable = true;
    config.user.name = "Paul Reitmayer";
    config.user.email = "paul.reitmayer@pm.me";
  };
}
