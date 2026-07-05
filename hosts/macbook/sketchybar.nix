{ config, pkgs, ... }:
let
  yabai = "${config.services.yabai.package}/bin/yabai";
  jq = "${pkgs.jq}/bin/jq";
  macmon = "${pkgs.macmon}/bin/macmon";

  # ── Catppuccin Mocha (0xAARRGGBB), aus quickshell Theme.qml ──
  base = "0xff1e1e2e";
  surface0 = "0xff313244";
  surface1 = "0xff45475a";
  overlay = "0xff6c7086";
  text = "0xffcdd6f4";
  subtext0 = "0xffa6adc8";
  sky = "0xff89dceb";
  teal = "0xff94e2d5";
  green = "0xffa6e3a1";
  yellow = "0xfff9e2af";
  peach = "0xfffab387";
  mauve = "0xffcba6f7";
  blue = "0xff89b4fa";
  sapphire = "0xff74c7ec";
  pink = "0xfff5c2e7";
  red = "0xfff38ba8";
  islandBorder = "0x8c89dceb"; # sky @ 0.55 alpha, wie Theme.borderColor(0.55)
  font = "JetBrainsMono Nerd Font";

  # Island-Stil (bracket-Hintergrund): base + sky-Border (dicker: 3) + radius 12.
  island = "background.color=${base} background.border_color=${islandBorder} background.border_width=3 background.corner_radius=12 background.height=34";

  # ── Scripts (''${VAR}=Bash, ${nix}=Nix-Interpolation) ──
  spaceScript = pkgs.writeShellScript "sb-space" ''
    sid="''${NAME#space.}"
    focused="$(${yabai} -m query --spaces --space 2>/dev/null | ${jq} -r '.index' 2>/dev/null)"
    if [ "$sid" = "$focused" ]; then
      sketchybar --set "$NAME" icon.color=${sky}
    else
      sketchybar --set "$NAME" icon.color=${overlay}
    fi
  '';

  clockScript = pkgs.writeShellScript "sb-clock" ''
    sketchybar --set "$NAME" label="$(date '+%a %d.%m  %H:%M')"
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    if ifconfig en0 2>/dev/null | grep -q 'status: active'; then
      sketchybar --set "$NAME" icon.color=${sky} label="WiFi" label.color=${text}
    else
      sketchybar --set "$NAME" icon.color=${overlay} label="off" label.color=${overlay}
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    vol="''${INFO}"
    [ -z "$vol" ] && vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
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

  # Net: kein macmon-Feld -> netstat-Delta ueber /tmp-State (updated beide Items).
  netScript = pkgs.writeShellScript "sb-net" ''
    S=/tmp/sb-net-en0
    read -r rx tx < <(netstat -ibn | awk '$1=="en0" && $3 ~ /Link/ {print $7, $10; exit}')
    if [ -z "$rx" ]; then sketchybar --set net_down label="-" --set net_up label="-"; exit; fi
    if [ -f "$S" ]; then read -r prx ptx < "$S"; else prx=$rx; ptx=$tx; fi
    echo "$rx $tx" > "$S"
    dt=3
    drx=$(( (rx - prx) / dt )); dtx=$(( (tx - ptx) / dt ))
    [ $drx -lt 0 ] && drx=0; [ $dtx -lt 0 ] && dtx=0
    human() { b=$1; if [ $b -ge 1048576 ]; then printf '%dM' $((b/1048576)); elif [ $b -ge 1024 ]; then printf '%dK' $((b/1024)); else printf '%dB' $b; fi; }
    sketchybar --set net_down label="$(human $drx)/s" --set net_up label="$(human $dtx)/s"
  '';

  # HW-Provider: EIN macmon-pipe-Prozess speist alle HW-Items (sudo-frei).
  hwProvider = pkgs.writeShellScript "sb-hw-provider" ''
    ${macmon} pipe -i 2000 | while read -r line; do
      vals="$(printf '%s' "$line" | ${jq} -r '
        [ (((.ecpu_usage[1] + .pcpu_usage[1]) / 2 * 100) | floor),
          ((.cpu_power * 10 | round) / 10),
          (.temp.cpu_temp_avg | floor),
          ((.gpu_usage[1] * 100) | floor),
          ((.gpu_power * 10 | round) / 10),
          (.temp.gpu_temp_avg | floor),
          ((.memory.ram_usage / 1073741824 * 10 | round) / 10)
        ] | @tsv')"
      IFS=$'\t' read -r cu cp ct gu gp gt mem <<< "$vals"
      sketchybar --set cpu_usage label="''${cu}%" \
                 --set cpu_power label="''${cp}W" \
                 --set cpu_temp  label="''${ct}°" \
                 --set gpu_usage label="''${gu}%" \
                 --set gpu_power label="''${gp}W" \
                 --set gpu_temp  label="''${gt}°" \
                 --set mem       label="''${mem}G"
    done
  '';
in
{
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  services.sketchybar = {
    enable = true;
    extraPackages = [ pkgs.jq pkgs.macmon ];

    config = ''
      #!/usr/bin/env bash

      sketchybar --bar \
        height=40 position=top color=0x00000000 \
        padding_left=12 padding_right=12 y_offset=6 sticky=on blur_radius=0

      sketchybar --default \
        icon.font="${font}:Bold:14.0" icon.color=${text} \
        label.font="${font}:Bold:13.0" label.color=${text} \
        padding_left=4 padding_right=4 \
        label.padding_left=4 label.padding_right=6 \
        icon.padding_left=8 icon.padding_right=4 \
        background.color=0x00000000

      # ── LINKS: Spaces als Dots (ohne Nummern) ──
      space_items=()
      for sid in $(seq 1 10); do
        sketchybar --add item space.$sid left \
          --set space.$sid \
            icon="●" icon.font="${font}:Bold:9.0" icon.color=${overlay} \
            icon.padding_left=5 icon.padding_right=5 \
            label.drawing=off background.drawing=off \
            script="${spaceScript}" \
            click_script="${yabai} -m space --focus $sid" \
          --subscribe space.$sid space_change
        space_items+=(space.$sid)
      done
      sketchybar --add bracket spaces "''${space_items[@]}" --set spaces ${island}

      # ── Abstand zwischen Spaces- und Metrics-Island ──
      sketchybar --add item lgap left \
        --set lgap icon.drawing=off label.drawing=off background.drawing=off \
          padding_left=10 padding_right=10

      # ── LINKS: Metrics-Island (macmon-gespeist) ──
      sketchybar --add item cpu_usage left --set cpu_usage icon="󰻠" icon.color=${green}  label="…" \
        --add item cpu_power left --set cpu_power icon="󱐋" icon.color=${peach}  label="…" \
        --add item cpu_temp  left --set cpu_temp  icon="󰔏" icon.color=${yellow} label="…" \
        --add item gpu_usage left --set gpu_usage icon="󰢮" icon.color=${teal}   label="…" \
        --add item gpu_power left --set gpu_power icon="󱐋" icon.color=${peach}  label="…" \
        --add item gpu_temp  left --set gpu_temp  icon="󰔏" icon.color=${yellow} label="…" \
        --add item mem       left --set mem       icon="󰍛" icon.color=${mauve}  label="…" \
        --add item net_down  left --set net_down  icon="󰁆" icon.color=${blue}     label="…" \
        --add item net_up    left --set net_up    icon="󰁞" icon.color=${sapphire} label="…" \
          script="${netScript}" update_freq=3
      sketchybar --add bracket metrics \
        cpu_usage cpu_power cpu_temp gpu_usage gpu_power gpu_temp mem net_down net_up \
        --set metrics ${island}

      # ── RECHTS: System-Island (wifi volume battery clock) ──
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
      sketchybar --add bracket system clock battery volume wifi --set system ${island}

      # ── HW-Provider starten (single instance) ──
      pkill -f sb-hw-provider 2>/dev/null || true
      nohup ${hwProvider} >/dev/null 2>&1 &

      sketchybar --update
    '';
  };
}
