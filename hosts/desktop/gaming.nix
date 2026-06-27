{ pkgs, ... }:
let
  # AMD X3D CCD-Umschalter (Cache- vs. Frequenz-CCD). gamemode ruft das via
  # sudo bei Spielstart/-ende auf; root noetig fuer den sysfs-Schreibzugriff.
  x3d-mode = pkgs.writeShellScriptBin "x3d-mode" ''
    set -eu
    mode="''${1:-}"
    case "$mode" in
      cache|frequency) ;;
      *) echo "Usage: x3d-mode <cache|frequency>" >&2; exit 1 ;;
    esac
    found=0
    for f in /sys/bus/platform/drivers/amd_x3d_vcache/*/amd_x3d_mode; do
      [ -e "$f" ] || continue
      printf '%s' "$mode" > "$f"
      found=1
    done
    [ "$found" -eq 1 ] || { echo "x3d-mode: kein amd_x3d_vcache-Geraet gefunden" >&2; exit 1; }
  '';
in
{
  # ── Steam + Proton-Env (aus Arch steam-env.conf — nur fuer Steam, nicht global) ──
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];   # GE-Proton (Arch nutzte proton-cachyos)
    package = pkgs.steam.override {
      # gamescope/gamemoderun/mangohud auch innerhalb der Steam-FHS verfuegbar
      extraPkgs = ps: with ps; [ mangohud gamescope gamemode ];
      extraEnv = {
        MANGOHUD = "1";                          # HUD in allen Vulkan-Spielen
        PULSE_LATENCY_MSEC = "60";               # Wine-Audio-Knistern vermeiden
        PROTON_ENABLE_WAYLAND = "1";             # natives Wayland (Hyprland)
        PROTON_ENABLE_HDR = "1";
        DXVK_HDR = "1";
        PROTON_DLSS_UPGRADE = "1";               # DLSS-DLLs auto-upgraden
        PROTON_ENABLE_NVAPI = "1";
        PROTON_ENABLE_NGX_UPDATER = "1";
        PROTON_NVIDIA_LIBS = "1";                # PhysX/CUDA im Prefix
        PROTON_LOCAL_SHADER_CACHE = "1";
        PROTON_USE_NTSYNC = "1";                 # ntsync statt fsync (/dev/ntsync)
        PROTON_VKD3D_HEAP = "1";                 # fixt NVIDIA-Xid-109-Crashes
        VKD3D_CONFIG = "descriptor_heap";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
      };
    };
  };

  # ── gamescope (HDR/adaptive-sync-Wrapper) ──
  programs.gamescope = {
    enable = true;
    capSysNice = true;   # Real-Time-Prioritaet
  };

  # ── gamemode + X3D-CCD-Switch ──
  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 0;
      cpu = {
        # 9950X3D: Kerne nicht parken, Spiel auf Kerne pinnen.
        park_cores = "no";
        pin_cores = "yes";
      };
      custom = {
        # Beim Spielen Cache-CCD bevorzugen, danach zurueck aufs Frequenz-CCD.
        start = "/run/wrappers/bin/sudo ${x3d-mode}/bin/x3d-mode cache";
        end = "/run/wrappers/bin/sudo ${x3d-mode}/bin/x3d-mode frequency";
      };
    };
  };

  # gamemoded laeuft als User -> NOPASSWD-sudo NUR fuer den x3d-mode-Schreibzugriff.
  security.sudo.extraRules = [{
    users = [ "paul" ];
    commands = [{
      command = "${x3d-mode}/bin/x3d-mode";
      options = [ "NOPASSWD" ];
    }];
  }];

  # ── zram (Groessenordnungen schneller als Disk-Swap) + Swap-Tuning ──
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;   # ram / 2
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # ── Tools ──
  environment.systemPackages = with pkgs; [
    mangohud
    x3d-mode
    vulkan-tools
    wineWow64Packages.stable
    winetricks
  ];
}
