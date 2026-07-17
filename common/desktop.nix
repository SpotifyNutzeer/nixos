{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;   # Hyprland via Universal Wayland Session Manager
  };
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Portal-Startreihenfolge: xdg-desktop-portal (Frontend) haengt sonst nur an
  # session.slice und startet damit VOR xdg-desktop-portal-hyprland, das erst
  # nach graphical-session.target (Compositor) hochkommt. Das Frontend liest die
  # AvailableCursorModes des Hyprland-Backends dann als 0 und cached das dauerhaft
  # -> Discords Screenshare-Anfrage mit cursor_mode=2 (embedded) wird mit
  # "Unavailable cursor mode 2" abgelehnt, SelectSources scheitert, der
  # hyprland-share-picker erscheint nie. Fix: Frontend erst nach dem Backend
  # starten, damit es die echten Cursor-Modi (3 = hidden|embedded) liest.
  systemd.user.services.xdg-desktop-portal = {
    overrideStrategy = "asDropin";
    after = [ "xdg-desktop-portal-hyprland.service" ];
    wants = [ "xdg-desktop-portal-hyprland.service" ];
  };

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
