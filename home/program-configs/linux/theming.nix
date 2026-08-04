{ pkgs, ... }:
{
  # Extends the shared Catppuccin base with Linux-specific theming.
  catppuccin = {
    cursors = {
      enable = true;
      # Default cursor: Catppuccin Mocha Dark instead of the teal accent.
      accent = "dark";
    };
    hyprland.enable = false;
    # hyprlock is themed manually in linux/hyprlock.nix.
    hyprlock.enable = false;

    # Catppuccin-tinted Papirus icons (sets gtk.iconTheme).
    gtk.icon.enable = true;

    # Qt theme via Kvantum.
    kvantum.enable = true;
  };

  # Theme Qt apps (e.g. Prism Launcher) via Kvantum + qt6ct.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };
  };

  # GTK widget theme (window colors/buttons).
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
