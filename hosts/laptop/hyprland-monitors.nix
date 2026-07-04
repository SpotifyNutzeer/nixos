{ ... }:
{
  # Internes Display; Pendant zu hosts/desktop/hyprland-monitors.nix.
  wayland.windowManager.hyprland.settings.monitorv2 = [
    {
      output = "eDP-1"; mode = "1920x1200@60"; position = "0x0";
      scale = "1.0"; bitdepth = 10; cm = "hdredid";
      sdr_min_luminance = 0.005; sdr_max_luminance = 250;
      min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22";
    }
  ];
}
