{ config, pkgs, ... }:
let
  # yabai-Binary mit vollem Pfad, damit skhd es zuverlaessig findet
  # (skhd startet Kommandos ueber sh ohne den vollen User-PATH).
  yabai = "${config.services.yabai.package}/bin/yabai";
in
{
  # ── yabai: Tiling-WM mit echtem BSP (= dwindle) ─────────────────────────────
  services.yabai = {
    enable = true;
    # Scripting Addition: noetig fuer Space-Steuerung (focus/move/create).
    # Setzt die passwordlose sudoers-Regel fuer `sudo yabai --load-sa`.
    # Verlangt partiell deaktiviertes SIP (siehe hosts/macbook/README.md).
    enableScriptingAddition = true;

    config = {
      layout = "bsp";

      # Gaps analog Hyprland (gaps_in=5 -> window_gap, gaps_out=10 -> padding).
      window_gap = 10;
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;

      split_ratio = 0.5;
      auto_balance = "off";
      window_placement = "second_child";

      # Hyprland input.follow_mouse=1 -> Fokus folgt Maus (ohne Raise).
      focus_follows_mouse = "autofocus";
      mouse_follows_focus = "off";

      # Hyprland bindm (Super+LMB move / Super+RMB resize) -> hier Alt.
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
    };

    extraConfig = ''
      # Scripting Addition laden (und nach Dock-Neustart automatisch neu laden).
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      sudo yabai --load-sa

      # Sicherstellen, dass 10 Spaces existieren (fuer alt-1..10). Idempotent:
      # erzeugt nur so viele, bis 10 erreicht sind (bei >=10 passiert nichts).
      space_count=$(yabai -m query --spaces | ${pkgs.jq}/bin/jq length)
      while [ "$space_count" -lt 10 ]; do
        yabai -m space --create
        space_count=$((space_count + 1))
      done
    '';
  };

  # ── skhd: Hotkey-Daemon (yabai macht kein Key-Binding selbst) ───────────────
  # Modifier = Alt (⌥), 1:1 zu den Hyprland-SUPER-Bindings / vorherigem AeroSpace.
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # ── Programme / Fenster ─────────────────────────────────
      alt - return          : open -na kitty
      alt + shift - q       : ${yabai} -m window --close
      alt - f               : ${yabai} -m window --toggle zoom-fullscreen
      alt - v               : ${yabai} -m window --toggle float
      alt - j               : ${yabai} -m window --toggle split
      alt - e               : open -a Finder
      alt + shift - return  : open raycast://

      # ── Fokus bewegen ───────────────────────────────────────
      alt - left            : ${yabai} -m window --focus west
      alt - right           : ${yabai} -m window --focus east
      alt - up              : ${yabai} -m window --focus north
      alt - down            : ${yabai} -m window --focus south

      # ── Workspaces (Spaces) wechseln 1..10 ──────────────────
      alt - 1 : ${yabai} -m space --focus 1
      alt - 2 : ${yabai} -m space --focus 2
      alt - 3 : ${yabai} -m space --focus 3
      alt - 4 : ${yabai} -m space --focus 4
      alt - 5 : ${yabai} -m space --focus 5
      alt - 6 : ${yabai} -m space --focus 6
      alt - 7 : ${yabai} -m space --focus 7
      alt - 8 : ${yabai} -m space --focus 8
      alt - 9 : ${yabai} -m space --focus 9
      alt - 0 : ${yabai} -m space --focus 10

      # ── Fenster in Space verschieben 1..10 (Fokus bleibt) ───
      alt + shift - 1 : ${yabai} -m window --space 1
      alt + shift - 2 : ${yabai} -m window --space 2
      alt + shift - 3 : ${yabai} -m window --space 3
      alt + shift - 4 : ${yabai} -m window --space 4
      alt + shift - 5 : ${yabai} -m window --space 5
      alt + shift - 6 : ${yabai} -m window --space 6
      alt + shift - 7 : ${yabai} -m window --space 7
      alt + shift - 8 : ${yabai} -m window --space 8
      alt + shift - 9 : ${yabai} -m window --space 9
      alt + shift - 0 : ${yabai} -m window --space 10
    '';
  };

  # ── JankyBorders: aktiver Fensterrahmen (ersetzt Hyprlands Gradient-Border) ──
  services.jankyborders = {
    enable = true;
    width = 2.0;                       # Hyprland border_size = 2
    style = "round";                   # Hyprland rounding = 10
    # Hyprland: col.active_border = $sky $teal 45deg ($sky=89dceb, $teal=94e2d5)
    active_color = "gradient(top_left=0xff89dceb,bottom_right=0xff94e2d5)";
    # Hyprland: col.inactive_border = rgba(45475aaa)
    inactive_color = "0xaa45475a";
  };
}
