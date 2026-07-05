{ config, pkgs, ... }:
let
  yabai = "${config.services.yabai.package}/bin/yabai";
  jq = "${pkgs.jq}/bin/jq";

  # ── Catppuccin Mocha (0xAARRGGBB) ──
  # base transparent fuer Bar-Hintergrund, sonst volle Deckung.
  barColor = "0xcc1e1e2e";
  surface0 = "0xff313244";
  overlay = "0xff6c7086";
  text = "0xffcdd6f4";
  teal = "0xff94e2d5";
  sky = "0xff89dceb";
  font = "JetBrainsMono Nerd Font";

  # ── Plugin-Scripts (Store-Pfade, referenziert per script=) ──
  # In Nix-''-Strings: ''${VAR} = literales Bash-${VAR}; ${nix} = Nix-Interpolation.

  spaceScript = pkgs.writeShellScript "sb-space" ''
    sid="''${NAME#space.}"
    focused="$(${yabai} -m query --spaces --space 2>/dev/null | ${jq} -r '.index' 2>/dev/null)"
    if [ "$sid" = "$focused" ]; then
      sketchybar --set "$NAME" label.highlight=on background.color=${surface0}
    else
      sketchybar --set "$NAME" label.highlight=off background.color=0x00000000
    fi
  '';

  frontAppScript = pkgs.writeShellScript "sb-front-app" ''
    name="''${INFO}"
    if [ -z "$name" ]; then
      name="$(${yabai} -m query --windows --window 2>/dev/null | ${jq} -r '.app // empty' 2>/dev/null)"
    fi
    sketchybar --set "$NAME" label="$name"
  '';

  clockScript = pkgs.writeShellScript "sb-clock" ''
    sketchybar --set "$NAME" label="$(date '+%a %d.%m  %H:%M')"
  '';

  batteryScript = pkgs.writeShellScript "sb-battery" ''
    batt="$(pmset -g batt)"
    pct="$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
    [ -z "$pct" ] && pct="?"
    if printf '%s' "$batt" | grep -q 'AC Power'; then
      sketchybar --set "$NAME" label="⚡ ''${pct}%"
    else
      sketchybar --set "$NAME" label="''${pct}%"
    fi
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    if ifconfig en0 2>/dev/null | grep -q 'status: active'; then
      sketchybar --set "$NAME" label="WiFi" label.color=${text}
    else
      sketchybar --set "$NAME" label="off" label.color=${overlay}
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    vol="''${INFO}"
    if [ -z "$vol" ]; then
      vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    fi
    sketchybar --set "$NAME" label="vol ''${vol}%"
  '';

  cpuScript = pkgs.writeShellScript "sb-cpu" ''
    used="$(top -l 1 -n 0 | awk '/CPU usage/ {u=$3; s=$5; gsub("%","",u); gsub("%","",s); printf "%d", u+s}')"
    [ -z "$used" ] && used="?"
    sketchybar --set "$NAME" label="cpu ''${used}%"
  '';
in
{
  # Nerd Font systemweit, damit sketchybar (und kitty) die Glyphen/Font hat.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  services.sketchybar = {
    enable = true;
    # Tools, die die Plugin-Scripts zur Laufzeit brauchen (jq ist per Store-Pfad
    # referenziert; der Rest liegt im System-PATH).
    extraPackages = [ pkgs.jq ];

    config = ''
      #!/usr/bin/env bash

      # ── Bar ──
      sketchybar --bar \
        height=32 \
        position=top \
        color=${barColor} \
        blur_radius=30 \
        padding_left=10 \
        padding_right=10 \
        margin=0 \
        y_offset=0 \
        sticky=on

      # ── Defaults ──
      sketchybar --default \
        icon.font="${font}:Bold:14.0" \
        icon.color=${text} \
        label.font="${font}:Bold:13.0" \
        label.color=${text} \
        padding_left=4 padding_right=4 \
        label.padding_left=3 label.padding_right=3 \
        icon.padding_left=6 icon.padding_right=3 \
        background.corner_radius=6 \
        background.height=24 \
        background.color=0x00000000

      # ── LINKS: Spaces 1..10 (aktives Space via yabai hervorgehoben) ──
      for sid in $(seq 1 10); do
        sketchybar --add item space.$sid left \
          --set space.$sid \
            icon.drawing=off \
            label="$sid" \
            label.color=${overlay} \
            label.highlight_color=${teal} \
            background.corner_radius=6 \
            background.height=24 \
            script="${spaceScript}" \
            click_script="${yabai} -m space --focus $sid" \
          --subscribe space.$sid space_change
      done

      # ── LINKS: fokussierte App ──
      sketchybar --add item front_app left \
        --set front_app \
          icon.drawing=off \
          label.color=${sky} \
          script="${frontAppScript}" \
        --subscribe front_app front_app_switched

      # ── RECHTS (aussen -> innen): clock, battery, wifi, volume, cpu ──
      sketchybar --add item clock right \
        --set clock update_freq=10 script="${clockScript}"

      sketchybar --add item battery right \
        --set battery update_freq=120 script="${batteryScript}" \
        --subscribe battery power_source_change system_woke

      sketchybar --add item wifi right \
        --set wifi update_freq=30 script="${wifiScript}"

      sketchybar --add item volume right \
        --set volume script="${volumeScript}" \
        --subscribe volume volume_change

      sketchybar --add item cpu right \
        --set cpu update_freq=5 script="${cpuScript}"

      sketchybar --update
    '';
  };
}
