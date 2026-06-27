{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;   # Hyprland via Universal Wayland Session Manager
  };
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Thunar Dateimanager (kein HM-Modul vorhanden -> NixOS-Modul).
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin   # Rechtsklick: Archive ent-/packen
      thunar-volman           # Auto-Mount von USB-Geraeten
    ];
  };
  programs.xfconf.enable = true;    # Thunar-Einstellungen persistent speichern
  services.gvfs.enable = true;      # Trash, Mounten, Netzwerk (smb/ftp), MTP
  services.tumbler.enable = true;   # Thumbnails (Bilder/PDF/Video)
}
