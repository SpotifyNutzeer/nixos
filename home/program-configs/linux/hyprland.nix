{ pkgs, dotfiles, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    package = null;
    portalPackage = null;

    # Session management is done by uwsm; the HM integration (default true) fires
    # `systemctl --user stop hyprland-session.target` on start, which since an HM
    # update tears down the entire uwsm session (incl. compositor) via
    # PropagatesStopTo=graphical-session.target -> Hyprland exits ~2s after login.
    systemd.enable = false;

    configType = "hyprlang";

    settings = {
      # ── Colors (only what hyprland.conf uses; full palette later into the shared module) ──
      "$sky"  = "rgb(89dceb)";
      "$teal" = "rgb(94e2d5)";

      # ── Variables ──
      "$mainMod"     = "SUPER";
      "$terminal"    = "kitty";
      "$fileManager" = "thunar";
      "$menu"        = "rofi -show drun";
      "$screenshot"  = "grimblast -f -n copy area";

      # NOTE: Session env now lives in ~/.config/uwsm/env-hyprland (see below).
      # The Hyprland env block would only inherit to direct exec-once children, not
      # to `uwsm app` scopes or D-Bus services. UWSM loads the uwsm env file into
      # the systemd user environment before the compositor -> all inherit consistently.

      general = {
        gaps_in = 5;
        # Defaults = zen variant (quickshell Theme.qml couples at runtime on theme
        # switch via hyprctl: zen -> these values, mocha/liquidglass -> 10 / $sky $teal 45deg / 10)
        gaps_out = "12, 22, 22, 22";
        border_size = 2;
        "col.active_border" = "$teal";
        "col.inactive_border" = "rgba(45475aaa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 12;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = { enabled = true; range = 4; render_power = 3; color = "rgba(11111bee)"; };
        blur = { enabled = true; size = 6; passes = 2; vibrancy = 0.1696; new_optimizations = false; };
        motion_blur = { enabled = true; samples = 7; };
        # The look lives entirely here; Theme.qml only toggles enabled (zen -> false,
        # mocha/liquidglass -> true). Inactive windows transparent -> focus indicator.
        glow = {
          enabled = false;
          range = 10;
          render_power = 3;
          color = "rgba(89dceb66) rgba(94e2d566) 45deg";
          color_inactive = "rgba(00000000)";
        };
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
          "glowangle,     1, 60,   linear, loop"
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

      dwindle = { preserve_split = true; };
      master = { new_status = "master"; };
      # Native scrolling layout (since Hyprland 0.51, usable here via toggle SUPER+TAB).
      scrolling = {
        column_width = 0.5;                                  # default width of new columns (0.1-1.0)
        focus_fit_method = 1;                                # fit the focused column instead of centering (0=center, 1=fit)
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0";   # presets that colresize +conf/-conf cycles through
        # direction = "right";                               # direction in which new columns grow (left/right/down/up)
      };
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
        touchpad = { 
          natural_scroll = true; 
          scroll_factor = 0.2;
        };
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

        # ── Toggle layout dwindle <-> scrolling ──
        "$mainMod, TAB, exec, if hyprctl getoption general:layout | grep -q scrolling; then hyprctl keyword general:layout dwindle; else hyprctl keyword general:layout scrolling; fi"

        # ── Scrolling layout (layoutmsg only acts in the scrolling layout, harmless in dwindle) ──
        "$mainMod, period, layoutmsg, move +col"              # scroll the tape one column to the right
        "$mainMod, comma, layoutmsg, move -col"               # scroll the tape one column to the left
        "$mainMod SHIFT, period, layoutmsg, swapcol r"        # swap the active column with its right neighbor column
        "$mainMod SHIFT, comma, layoutmsg, swapcol l"         # swap the active column with its left neighbor column
        "$mainMod, R, layoutmsg, colresize +conf"             # cycle column width forward through the presets
        "$mainMod SHIFT, R, layoutmsg, colresize -conf"       # cycle column width backward through the presets
        "$mainMod, G, layoutmsg, fit visible"                 # neatly fit all currently visible columns
        "$mainMod, M, layoutmsg, fit expand"                  # let the active window fill the free space
        "$mainMod, C, layoutmsg, consume"                     # suck the window into the previous column (stack vertically)
        "$mainMod, X, layoutmsg, expel"                       # detach the window from its column into its own column
        "$mainMod, U, layoutmsg, promote"                     # promote the window into a new column of its own

        "$mainMod SHIFT, S, exec, $screenshot"
        "$mainMod, L, exec, hyprlock"
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
        { name = "thunar-file-operation-float"; "match:class" = "^thunar$"; "match:title" = "^File Operation Progress$"; float = "yes"; size = "600 300"; center = 1; }
      ];

      xwayland = { enabled = true; force_zero_scaling = true; };
      exec-once = [
        # UWSM readiness: signals to wayland-wm@hyprland.service that the
        # compositor is up. Exports WAYLAND_DISPLAY/DISPLAY into the systemd
        # user and D-Bus environment and activates graphical-session.target. MUST
        # run first, otherwise the session unit hangs in the activating timeout.
        "uwsm finalize"

        # NVIDIA 3-display cold-boot bug: if all monitors come up at the same time,
        # the main monitor does not get 4K@240 (DSC/head allocation). Fix: briefly take
        # DP-2 out (main jumps to 240), then back via reload with the full HDR config.
        # "sleep 3; hyprctl keyword monitor 'DP-2,disable'; hyprctl keyword monitor 'DP-3,disable'; sleep 1; hyprctl reload"

        # GUI apps via `uwsm app --`: they land in their own systemd scopes (app.slice)
        # instead of as children of the compositor -> clean stopping at session end,
        # own cgroup/OOM limits, correct placement in the session tree.
        "uwsm app -- quickshell"
        "uwsm app -- discord"
        # Tidal (Electron/Chromium) prefers PulseAudio but falls back to ALSA
        # if it gets no connection to pipewire-pulse at startup.
        # pipewire-pulse.service is socket-activated (Type=simple): the socket is
        # there early, but the service only starts COLD on the first client connect.
        # At boot, Tidal's connect triggers this cold start, whose latency runs into
        # Chromium's Pulse handshake timeout -> ALSA fallback. Depending on backend,
        # Tidal registers with WirePlumber under a different identity (pulse=Chromium,
        # alsa=PipeWire ALSA [tidal-hifi]), which makes the target set in pavucontrol/
        # via the pulse.rules get lost after a restart.
        # Fix: explicitly warm-start pipewire-pulse BEFORE Tidal (systemctl start
        # blocks until active) so that Tidal deterministically goes via PulseAudio
        # and the pulse.rules rule (see hosts/desktop/pipewire.nix) takes effect.
        "systemctl --user start pipewire-pulse.service; uwsm app -- tidal-hifi"
        "uwsm app -- awww-daemon"
        "sleep 1; awww img ${dotfiles}/wallpapers/firewatchcatpuccinmochagreen.png"
        "uwsm app -- streamcontroller -b"
        "uwsm app -- steam -silent"
        "uwsm app -- gsr-ui"
        "uwsm app -- Telegram -startintray"
        "uwsm app -- seadrive-gui"
      ];
    };
  };

  # UWSM session environment: sourced BEFORE the compositor and loaded into the
  # systemd user + D-Bus activation environment. Thus reaches the compositor
  # itself, all `uwsm app` scopes and D-Bus-activated services (in contrast to the
  # Hyprland env block, which only reaches direct children). Single source of truth.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export XCURSOR_SIZE=24
    export XCURSOR_THEME=catppuccin-mocha-dark-cursors
    export HYPRCURSOR_SIZE=24
    export QT_QPA_PLATFORMTHEME=qt6ct
    export QT_STYLE_OVERRIDE=kvantum
  '';

  # Companion tools the session needs NOW (launcher). Grows in round 2.
  home.packages = with pkgs; [ rofi quickshell jq cava awww ];
}
