{ pkgs, ... }:
{
  home.username = "paul";
  home.homeDirectory = "/home/paul";
  home.stateVersion = "26.05";
  
  programs.starship.enable = true;
}
