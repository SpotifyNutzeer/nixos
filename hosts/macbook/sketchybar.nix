{ config, pkgs, ... }:
let
  yabai = "${config.services.yabai.package}/bin/yabai";
  jq = "${pkgs.jq}/bin/jq";

  # ── Catppuccin Mocha (0xAARRGGBB), 1:1 aus quickshell Theme.qml ──
  base = "0xff1e1e2e";
  surface0 = "0xff313244";
  text = "0xffcdd6f4";
  subtext0 = "0xffa6adc8";
  sky = "0xff89dceb";
  green = "0xffa6e3a1";
  mauve = "0xffcba6f7";
  blue = "0xff89b4fa";
  pink = "0xfff5c2e7";
  peach = "0xfffab387";
  red = "0xfff38ba8";
  # Island-Border: sky bei 0.55 Alpha (= 0x8c) — wie Theme.borderColor(0.55).
  islandBorder = "0x8c89dceb";
  font = "JetBrainsMono Nerd Font";

  # Island-Stil (bracket-Hintergrund): base-Fläche + sky-Border + radius 12.
  island = "background.color=${base} background.border_color=${islandBorder} background.border_width=2 background.corner_radius=12 background.height=34";

  # ── Plugin-Scripts ──
  # ''${VAR} = literales Bash-${VAR}; ${nix} = Nix-Interpolation.
  spaceScript = pkgs.writeShellScript "sb-space" ''
    sid="''${NAME#space.}"
    focused="$(${yabai} -m query --spaces --space 2>/dev/null | ${jq} -r '.index' 2>/dev/null)"
    if [ "$sid" = "$focused" ]; then
      sketchybar --set "$NAME" background.color=${sky} label.color=${base}
    else
      sketchybar --set "$NAME" background.color=${surface0} label.color=${subtext0}
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

  cpuScript = pkgs.writeShellScript "sb-cpu" ''
    used="$(top -l 1 -n 0 | awk '/CPU usage/ {u=$3; s=$5; gsub("%","",u); gsub("%","",s); printf "%d", u+s}')"
    [ -z "$used" ] && used="?"
    sketchybar --set "$NAME" label="''${used}%"
  '';

  ramScript = pkgs.writeShellScript "sb-ram" ''
    used="$(top -l 1 -n 0 | awk '/PhysMem/ {print $2}')"
    [ -z "$used" ] && used="?"
    sketchybar --set "$NAME" label="$used"
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    if ifconfig en0 2>/dev/null | grep -q 'status: active'; then
      sketchybar --set "$NAME" icon.color=${sky} label="WiFi" label.color=${text}
    else
      sketchybar --set "$NAME" icon.color=${subtext0} label="off" label.color=${subtext0}
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    vol="''${INFO}"
    if [ -z "$vol" ]; then
      vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    fi
    sketchybar --set "$NAME" label="''${vol}%"
  '';

  batteryScript = pkgs.writeShellScript "sb-battery" ''
    batt="$(pmset -g batt)"
    pct="$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
    [ -z "$pct" ] && pct="?"
    if printf '%s' "$batt" | grep -q 'AC Power'; then
      sketchybar --set "$NAME" icon="󰂄" icon.color=${green} label="''${pct}%"
    elif [ "$pct" != "?" ] && [ "$pct" -le 15 ] 2>/dev/null; then
      sketchybar --set "$NAME" icon="󰁻" icon.color=${red} label="''${pct}%"
    else
      sketchybar --set "$NAME" icon="󰁹" icon.color=${text} label="''${pct}%"
    fi
  '';
in
{
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  services.sketchybar = {
    enable = true;
    extraPackages = [ pkgs.jq ];

    config = ''
      #!/usr/bin/env bash

      # ── Bar: transparent, Islands schweben ──
      sketchybar --bar \
        height=40 \
        position=top \
        color=0x00000000 \
        padding_left=12 \
        padding_right=12 \
        y_offset=6 \
        sticky=on \
        blur_radius=0

      # ── Defaults ──
      sketchybar --default \
        icon.font="${font}:Bold:14.0" \
        icon.color=${text} \
        label.font="${font}:Bold:13.0" \
        label.color=${text} \
        padding_left=4 padding_right=4 \
        label.padding_left=4 label.padding_right=4 \
        icon.padding_left=8 icon.padding_right=4 \
        background.color=0x00000000

      # ── LINKS: Spaces-Island (innere Pills) ──
      space_items=()
      for sid in $(seq 1 10); do
        sketchybar --add item space.$sid left \
          --set space.$sid \
            icon.drawing=off \
            label="$sid" \
            label.color=${subtext0} \
            label.padding_left=9 label.padding_right=9 \
            background.color=${surface0} \
            background.corner_radius=6 \
            background.height=24 \
            script="${spaceScript}" \
            click_script="${yabai} -m space --focus $sid" \
          --subscribe space.$sid space_change
        space_items+=(space.$sid)
      done
      sketchybar --add bracket spaces "''${space_items[@]}" \
        --set spaces ${island}

      # ── LINKS: App-Island ──
      sketchybar --add item front_app left \
        --set front_app \
          icon="󰖯" icon.color=${blue} \
          label.color=${text} label.max_chars=32 \
          script="${frontAppScript}" \
        --subscribe front_app front_app_switched
      sketchybar --add bracket app front_app \
        --set app ${island}

      # ── RECHTS: System-Island (aussen) — clock, battery, volume, wifi ──
      sketchybar --add item clock right \
        --set clock icon="󰃰" icon.color=${pink} update_freq=10 script="${clockScript}"
      sketchybar --add item battery right \
        --set battery update_freq=120 script="${batteryScript}" \
        --subscribe battery power_source_change system_woke
      sketchybar --add item volume right \
        --set volume icon="󰕾" icon.color=${sky} script="${volumeScript}" \
        --subscribe volume volume_change
      sketchybar --add item wifi right \
        --set wifi icon="󰖩" update_freq=30 script="${wifiScript}"
      sketchybar --add bracket system clock battery volume wifi \
        --set system ${island}

      # ── RECHTS: Stats-Island (innen) — cpu, ram ──
      sketchybar --add item cpu right \
        --set cpu icon="󰻠" icon.color=${green} update_freq=5 script="${cpuScript}"
      sketchybar --add item ram right \
        --set ram icon="󰍛" icon.color=${mauve} update_freq=5 script="${ramScript}"
      sketchybar --add bracket stats cpu ram \
        --set stats ${island}

      sketchybar --update
    '';
  };
}
