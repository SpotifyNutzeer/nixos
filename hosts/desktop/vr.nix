{ pkgs, ... }:
{
  # WiVRn: OpenXR runtime + streaming server (Monado-based) for the Pico 4.
  # xrizer is bundled in the package as an OpenVR compat layer; the server
  # manages openvrpaths.vrpath itself and registers the runtime via a
  # manifest under /run/current-system/sw/share/openxr (Steam finds it
  # through PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES) — SteamVR is not
  # installed. The module enables Avahi/mDNS automatically.
  services.wivrn = {
    enable = true;
    openFirewall = true;             # 9757 TCP/UDP for the stream
    autoStart = true;                # server starts with the user session
    highPriority = true;             # CAP_SYS_NICE for async reprojection
    # Make the runtime visible inside the Steam pressure-vessel sandbox
    # (steam.enable is on by default). Only takes effect after re-login.
    steam.importOXRRuntimes = true;
    # config/monadoEnvironment deliberately empty: Vulkan encode runs on NVIDIA
    # without a CUDA build; encoder/bitrate is set in the WiVRn dashboard.
  };

  environment.systemPackages = with pkgs; [
    wayvr          # desktop overlay in VR (successor of wlx-overlay-s)
    android-tools  # adb for the one-time client installation onto the headset
  ];
}
