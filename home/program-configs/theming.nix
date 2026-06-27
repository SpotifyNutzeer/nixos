{ pkgs, catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";

    cursors.enable = true;
    hyprland.enable = false;

    # Catppuccin-eingefärbte Papirus-Icons. Setzt gtk.iconTheme automatisch auf
    # "Papirus-Dark" + catppuccin-papirus-folders (mocha/teal). Via autoEnable
    # ohnehin an; explizit zur Klarheit.
    gtk.icon.enable = true;

    # Qt-Theme via Kvantum (schreibt die Kvantum-Theme-Dateien + setzt sie aktiv).
    kvantum.enable = true;
  };

  # Qt-Apps (z.B. Prism Launcher) über Kvantum + qt6ct themen.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };
  };

  # Top-level HM-gtk: installiert das von catppuccin gesetzte Icon-Theme-Paket
  # (→ rofi findet "Papirus-Dark") und lässt GTK-Apps Icons + Theme nutzen.
  gtk = {
    enable = true;
    # GTK-Widget-Theme (Fensterfarben/Buttons) — setzt catppuccin/nix NICHT selbst.
    theme = {
      name = "catppuccin-mocha-teal-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "teal" ];
        variant = "mocha";
      };
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    size = 24;
  };
}
