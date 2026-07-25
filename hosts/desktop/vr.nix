{ pkgs, ... }:
{
  # WiVRn: OpenXR-Runtime + Streaming-Server (Monado-basiert) fuer die Pico 4.
  # xrizer ist im Paket als OpenVR-Compat-Layer gebuendelt; der Server
  # verwaltet openvrpaths.vrpath selbst und registriert die Runtime via
  # Manifest unter /run/current-system/sw/share/openxr (Steam findet sie
  # ueber PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES) — SteamVR wird nicht
  # installiert. Avahi/mDNS aktiviert das Modul automatisch.
  services.wivrn = {
    enable = true;
    openFirewall = true;             # 9757 TCP/UDP fuer den Stream
    autoStart = true;                # Server startet mit der User-Session
    highPriority = true;             # CAP_SYS_NICE fuer Async-Reprojection
    # Runtime in der Steam-Pressure-Vessel-Sandbox sichtbar machen
    # (steam.enable ist default-an). Wird erst nach Re-Login wirksam.
    steam.importOXRRuntimes = true;
    # config/monadoEnvironment bewusst leer: Vulkan-Encode laeuft auf NVIDIA
    # ohne CUDA-Build, Encoder/Bitrate stellt man im WiVRn-Dashboard ein.
  };

  environment.systemPackages = with pkgs; [
    wayvr          # Desktop-Overlay in VR (Nachfolger von wlx-overlay-s)
    android-tools  # adb fuer die einmalige Client-Installation aufs Headset
  ];
}
