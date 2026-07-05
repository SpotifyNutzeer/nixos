{ catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  # Plattformunabhaengige Catppuccin-Basis: themt via autoEnable alle aktivierten
  # CLI-/TUI-Programme (kitty, fish, starship, tmux, bat, vim). GTK/Qt/Kvantum/Cursor
  # sind Linux-Konzepte und liegen in linux/theming.nix.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
  };
}
