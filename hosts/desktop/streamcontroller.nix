{ pkgs, ... }:
{
  # StreamController (Stream Deck control).
  environment.systemPackages = [ pkgs.streamcontroller ];

  # The udev rule from the package enables access to the Stream Deck USB HID
  # without root (otherwise StreamController does not find the device).
  services.udev.packages = [ pkgs.streamcontroller ];
}
