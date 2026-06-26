{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
  ];
  
  programs.nano.enable = false;
  programs.git = {
    enable = true;
    config.user.name = "Paul Reitmayer";
    config.user.email = "paul.reitmayer@pm.me";
  };
}
