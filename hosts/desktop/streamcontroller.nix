{ pkgs, streamcontroller-tidal, ... }:
{
  # StreamController (Stream-Deck-Steuerung). websockets wird per Overlay in
  # flake.nix ins Paket gezogen, siehe Kommentar dort.
  environment.systemPackages = [ pkgs.streamcontroller ];

  # udev-Regel aus dem Paket aktiviert den Zugriff auf das Stream-Deck-USB-HID
  # ohne root (sonst findet StreamController das Geraet nicht).
  services.udev.packages = [ pkgs.streamcontroller ];

  # Tidal-Plugin deklarativ in den StreamController-Plugin-Ordner verlinken.
  # StreamController nutzt nativ (kein Flatpak) den Datenpfad
  # ~/.var/app/com.core447.StreamController/data, Plugins liegen darunter.
  # Der Ordnername muss der plugin-id aus manifest.json entsprechen.
  home-manager.users.paul.home.file.".var/app/com.core447.StreamController/data/plugins/wtf_paul_TidalController".source =
    streamcontroller-tidal;
}
