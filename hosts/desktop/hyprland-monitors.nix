{ ... }:
{
  # Desktop-spezifische Monitore + Workspace-Zuordnung (aus der geteilten
  # hyprland.nix herausgezogen; der Laptop hat sein eigenes Pendant).
  wayland.windowManager.hyprland.settings = {
    monitorv2 = [
      {
        output = "HDMI-A-1"; mode = "3840x2160@240.00"; position = "0x1440";
        scale = "1.0"; bitdepth = 10; cm = "hdredid";
        sdr_min_luminance = 0.005; sdr_max_luminance = 250;
        min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22"; vrr = 2;
      }
      {
        output = "DP-2"; mode = "3440x1440@164.90"; position = "0x0";
        bitdepth = 10; cm = "hdredid";
        sdr_min_luminance = 0.005; sdr_max_luminance = 250;
        min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22"; vrr = 2;
      }
      { output = "DP-3"; mode = "2560x720@60"; position = "0x3600"; }
    ];

    workspace = [
      "1, monitor:HDMI-A-1"
      "2, monitor:DP-3"
      "3, monitor:DP-2"
    ];
  };
}
