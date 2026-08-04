{ pkgs, streamcontroller-tidal, ... }:
{
  # StreamController (Stream Deck control). websockets is pulled into the
  # package via an overlay in flake.nix, see the comment there.
  environment.systemPackages = [ pkgs.streamcontroller ];

  # The udev rule from the package enables access to the Stream Deck USB HID
  # without root (otherwise StreamController does not find the device).
  services.udev.packages = [ pkgs.streamcontroller ];

  # Link the Tidal plugin declaratively into the StreamController plugin folder.
  # StreamController natively (no Flatpak) uses the data path
  # ~/.var/app/com.core447.StreamController/data, plugins live underneath it.
  # The folder name must match the plugin-id from manifest.json.
  home-manager.users.paul.home.file.".var/app/com.core447.StreamController/data/plugins/wtf_paul_TidalController".source =
    streamcontroller-tidal;
}
