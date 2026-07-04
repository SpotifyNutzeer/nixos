{ pkgs, dotfiles, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    package = null;
    portalPackage = null;

    configType = "hyprlang";

    settings = {
      # ── Farben (nur was hyprland.conf nutzt; volle Palette spaeter ins shared-Modul) ──
      "$sky"  = "rgb(89dceb)";
      "$teal" = "rgb(94e2d5)";

      # ── Variablen ──
      "$mainMod"     = "SUPER";
      "$terminal"    = "kitty";
      "$fileManager" = "thunar";
      "$menu"        = "rofi -show drun";
      "$screenshot"  = "grimblast -f -n copy area";

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

      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,catppuccin-mocha-teal-cursors"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_STYLE_OVERRIDE,kvantum"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "$sky $teal 45deg";
        "col.inactive_border" = "rgba(45475aaa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = { enabled = true; range = 4; render_power = 3; color = "rgba(11111bee)"; };
        blur = { enabled = true; size = 6; passes = 2; vibrancy = 0.1696; new_optimizations = false; };
      };

      layerrule = [ "blur on, ignore_alpha 0.05, match:namespace quickshell" ];

      animations = {
        enabled = "yes, please :)";
        bezier = [
          "easeOutQuint,   0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear,         0, 0, 1, 1"
          "almostLinear,   0.5, 0.5, 0.75, 1"
          "quick,          0.15, 0, 0.1, 1"
        ];
        animation = [
          "global,        1, 10,   default"
          "border,        1, 5.39, easeOutQuint"
          "borderangle,   1, 60,   linear, loop"
          "windows,       1, 4.79, easeOutQuint"
          "windowsIn,     1, 4.1,  easeOutQuint, popin 87%"
          "windowsOut,    1, 1.49, linear, popin 87%"
          "fadeIn,        1, 1.73, almostLinear"
          "fadeOut,       1, 1.46, almostLinear"
          "fade,          1, 3.03, quick"
          "layers,        1, 3.81, easeOutQuint"
          "layersIn,      1, 4,    easeOutQuint, fade"
          "layersOut,     1, 1.5,  linear, fade"
          "fadeLayersIn,  1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces,    1, 1.94, almostLinear, fade"
          "workspacesIn,  1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
          "zoomFactor,    1, 7,    quick"
        ];
      };

      workspace = [
        "1, monitor:HDMI-A-1"
        "2, monitor:DP-3"
        "3, monitor:DP-2"
      ];

      dwindle = { preserve_split = true; };
      master = { new_status = "master"; };
      misc = { force_default_wallpaper = -1; disable_hyprland_logo = false; };
      render = {
        # use_shader_blur_blend = 1;
        direct_scanout = false;
        cm_sdr_eotf = "gamma22";
        cm_auto_hdr = 0;
      };

      input = {
        kb_layout = "de";
        accel_profile = "flat";
        follow_mouse = 1;
        sensitivity = -0.1;
        touchpad = { natural_scroll = false; };
      };

      gesture = [ "3, horizontal, workspace" ];
      device = [ { name = "epic-mouse-v1"; sensitivity = -0.5; } ];

      bind = [
        "$mainMod, Return, exec, $terminal"
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod SHIFT, E, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, F, fullscreen"
        "$mainMod SHIFT, Return, exec, $menu"
        "$mainMod, P, pseudo,"
        "$mainMod, J, layoutmsg, togglesplit"
        "$mainMod SHIFT, S, exec, $screenshot"
        "$mainMod SHIFT, T, exec, ~/.config/quickshell/scripts/theme-switch.sh menu"
        "$mainMod ALT, R, exec, killall -SIGUSR1 gpu-screen-recorder"
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod CTRL, S, movetoworkspace, special:magic"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      windowrule = [
        { name = "suppress-maximize-events"; "match:class" = ".*"; suppress_event = "maximize"; }
        { name = "fix-xwayland-drags"; "match:class" = "^$"; "match:title" = "^$"; "match:xwayland" = true; "match:float" = true; "match:fullscreen" = false; "match:pin" = false; no_focus = true; }
        { name = "move-hyprland-run"; "match:class" = "hyprland-run"; move = "20 monitor_h-120"; float = "yes"; }
        { name = "discord-position"; "match:class" = "^discord$"; workspace = "2"; }
        { name = "tidal-position"; "match:class" = "^tidal-hifi$"; workspace = "2"; }
        { name = "steam-bigpicture"; "match:class" = "^steam$"; "match:title" = "^Steam Big Picture Mode$"; monitor = "HDMI-A-1"; fullscreen = 1; }
        { name = "bitwarden-extension"; "match:class" = "^brave-nngceckbapebfimnlniiiahkandclblb-Default$"; float = true; }
        { name = "seadrive-prefetch-float"; "match:class" = "^seadrive-prefetch$"; float = "yes"; size = "720 200"; center = 1; }
      ];

      xwayland = { enabled = true; force_zero_scaling = true; };
      exec-once = [
        # NVIDIA-3-Display-Kaltstart-Bug: kommen alle Monitore gleichzeitig hoch,
        # bekommt der Hauptmonitor kein 4K@240 (DSC-/Head-Allokation). Fix: DP-2 kurz
        # rausnehmen (Haupt springt auf 240), dann via reload mit voller HDR-Config zurueck.
        # "sleep 3; hyprctl keyword monitor 'DP-2,disable'; hyprctl keyword monitor 'DP-3,disable'; sleep 1; hyprctl reload"
        "quickshell"
        "discord"
        "sleep 5; tidal-hifi"
        "awww-daemon"
        "sleep 1; awww img ${dotfiles}/wallpapers/firewatchcatpuccinmochagreen.png"
        "streamcontroller -b"
        "steam -silent"
        "gsr-ui"
        "Telegram -startintray"
        "seadrive-gui"
      ];
    };
  };

  # Companion-Tool, das die Session JETZT braucht (Launcher). Wächst in Round 2.
  home.packages = with pkgs; [ rofi quickshell jq cava awww ];
}
