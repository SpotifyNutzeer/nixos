{ ... }:
{
  imports = [
    ./home-shared.nix
    ./program-configs/darwin/ssh.nix
  ];

  home.username = "paulweber";
  home.homeDirectory = "/Users/paulweber";
}
