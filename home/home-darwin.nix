{ ... }:
{
  imports = [
    ./home-shared.nix
    ./program-configs/darwin/ssh.nix
    ./program-configs/darwin/aerospace.nix
  ];

  home.username = "paulweber";
  home.homeDirectory = "/Users/paulweber";
}
