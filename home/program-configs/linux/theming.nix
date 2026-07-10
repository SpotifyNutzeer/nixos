{ pkgs, ... }:
{
  # Ergaenzt die shared Catppuccin-Basis um Linux-spezifisches Theming.
  catppuccin = {
    cursors = {
      enable = true;
      # Default-Cursor: Catppuccin Mocha Dark statt des Teal-Akzents.
      accent = "dark";
    };
    hyprland.enable = false;
    # hyprlock wird manuell in linux/hyprlock.nix gethemet.
    hyprlock.enable = false;

    # Catppuccin-eingefaerbte Papirus-Icons (setzt gtk.iconTheme).
    gtk.icon.enable = true;

    # Qt-Theme via Kvantum.
    kvantum.enable = true;
  };

  # Qt-Apps (z.B. Prism Launcher) ueber Kvantum + qt6ct themen.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };
  };

  # GTK-Widget-Theme (Fensterfarben/Buttons).
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-teal-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "teal" ];
        variant = "mocha";
      };
    };
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    size = 24;

  };
}
