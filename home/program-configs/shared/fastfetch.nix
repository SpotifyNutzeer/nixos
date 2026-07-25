{ ... }:
let
  # Catppuccin Mocha, passend zum Starship-Powerline-Schema (starship.nix):
  # System-Block teal, Hardware-Block sky, Gedimmtes overlay0.
  teal = "38;2;148;226;213";
  sky = "38;2;137;220;235";
  dim = "38;2;108;112;134";
  m = type: key: keyColor: { inherit type key keyColor; };
in
{
  # hyfetch (backend = "fastfetch") liefert nur das Logo; Auswahl und Farben der
  # Info-Zeilen kommen aus dieser Config (~/.config/fastfetch/config.jsonc).
  # enable installiert das Binary auf beiden Plattformen (macOS: kein extra
  # home.packages in darwin/hyfetch.nix mehr noetig).
  programs.fastfetch = {
    enable = true;
    settings = {
      display = {
        separator = " ";
        key.width = 12;
      };
      modules = [
        {
          type = "title";
          color = {
            user = teal;
            at = dim;
            host = sky;
          };
        }
        {
          type = "custom";
          format = "─────────────────────";
          outputColor = dim;
        }
        (m "os" " OS" teal)
        (m "kernel" " Kernel" teal)
        (m "uptime" " Uptime" teal)
        (m "packages" "󰏖 Packages" teal)
        (m "shell" " Shell" teal)
        (m "wm" " WM" teal)
        (m "cpu" " CPU" sky)
        (m "memory" "󰑭 RAM" sky)
        (m "disk" "󰋊 Disk" sky)
        { type = "break"; }
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
