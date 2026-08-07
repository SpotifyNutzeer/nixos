{ pkgs, ... }:
let
  # Two upstream mismatches in the nixpkgs 1.5.0-beta.14 packaging (2026-08-07):
  #
  # 1. streamcontroller-streamdeck 0.1.7 dropped the legacy DeviceManager.USB_*
  #    aliases; those IDs now only live in StreamDeck.ProductIDs. StreamController
  #    still reads them off DeviceManager, so every deck reset dies with
  #    "type object 'DeviceManager' has no attribute 'USB_VID_ELGATO'".
  # 2. The wrapper's GI_TYPELIB_PATH carries no WebKit, so plugins that open a
  #    GTK4 web view for OAuth (de_outsider_Spotify) fail to import with
  #    "Namespace WebKit not available".
  #
  # Drop both once nixpkgs ships a StreamController that matches streamdeck 0.1.7.
  streamcontroller = pkgs.streamcontroller.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.webkitgtk_6_0 ];

    postPatch = (old.postPatch or "") + ''
      for f in main.py src/backend/DeckManagement/DeckManager.py; do
        sed -i \
          -e '/^from StreamDeck\.DeviceManager import DeviceManager$/a from StreamDeck.ProductIDs import USBVendorIDs, USBProductIDs' \
          -e 's/DeviceManager\.USB_VID_/USBVendorIDs.USB_VID_/g' \
          -e 's/DeviceManager\.USB_PID_/USBProductIDs.USB_PID_/g' \
          "$f"
      done
    '';
  });
in
{
  # StreamController (Stream Deck control).
  environment.systemPackages = [ streamcontroller ];

  # The udev rule from the package enables access to the Stream Deck USB HID
  # without root (otherwise StreamController does not find the device).
  services.udev.packages = [ streamcontroller ];
}
