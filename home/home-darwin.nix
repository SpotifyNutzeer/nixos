{ ... }:
{
  imports = [
    ./home-shared.nix
    ./program-configs/darwin/ssh.nix
    # aerospace bleibt als Backup im Repo (home/program-configs/darwin/aerospace.nix),
    # ist aber nicht importiert: WM ist jetzt yabai (hosts/macbook/yabai.nix).
    # Zwei WMs wuerden kollidieren. Wird geloescht, sobald yabai stabil laeuft.
  ];

  home.username = "paulweber";
  home.homeDirectory = "/Users/paulweber";
}
