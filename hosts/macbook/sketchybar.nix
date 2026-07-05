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
  islandBorder = "0xff89dceb"; # volle Deckkraft -> praesenter auf dunklem Grund
  font = "JetBrainsMono Nerd Font";

  # Island-Stil (bracket-Hintergrund): base + heller sky-Border, Hoehe/Radius
  # exakt wie quickshell (height 40, radius 12).
  island = "background.color=${base} background.border_color=${islandBorder} background.border_width=2 background.corner_radius=12 background.height=30";

  # ── Scripts (''${VAR}=Bash, ${nix}=Nix-Interpolation) ──
  clockScript = pkgs.writeShellScript "sb-clock" ''
    sketchybar --set "$NAME" label="$(date '+%a %d.%m  %H:%M')"
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    ssid="$(ipconfig getsummary en0 2>/dev/null | sed -n 's/.*SSID : //p' | head -1)"
    if [ -n "$ssid" ]; then
      sketchybar --set "$NAME" icon.color=${sky} label="$ssid" label.color=${text}
    else
      sketchybar --set "$NAME" icon.color=${overlay} label="off" label.color=${overlay}
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    vol="''${INFO}"
    [ -z "$vol" ] && vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    sketchybar --set "$NAME" label="$(printf '%-4s' "''${vol}%")"
  '';

  # Batterie: Prozent/Status/Zeit aus pmset, Leistung (W) aus ioreg
  # (Amperage[mA] x Voltage[mV] / 1e6; Amperage ist unsigned-wraparound ->
  # bash 64-bit aufloesen). Setzt drei Items: battery, battery_power, battery_time.
  batteryScript = pkgs.writeShellScript "sb-battery" ''
    pm="$(pmset -g batt)"
    pct="$(printf '%s' "$pm" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
    [ -z "$pct" ] && pct="?"
    if printf '%s' "$pm" | grep -q 'AC Power'; then charging=1; else charging=0; fi
    tm="$(printf '%s' "$pm" | grep -Eo '[0-9]+:[0-9]+' | head -1)"

    # Leistung aus ioreg
    io="$(ioreg -rn AppleSmartBattery)"
    amp_raw="$(printf '%s' "$io" | awk '/"Amperage" =/{print $NF; exit}')"
    volt="$(printf '%s' "$io" | awk '/"Voltage" =/{print $NF; exit}')"
    watts=""
    if [ -n "$amp_raw" ] && [ -n "$volt" ]; then
      amp=$(( amp_raw ))
      watts="$(awk -v a="$amp" -v v="$volt" 'BEGIN{p=a*v/1e6; if(p<0)p=-p; printf "%.0f", p}')"
    fi

    # Icon/Farbe fuers Prozent-Item
    if [ "$charging" = 1 ]; then
      bicon="󰂄"; bcolor=${green}
    elif [ "$pct" != "?" ] && [ "$pct" -le 15 ] 2>/dev/null; then
      bicon="󰁻"; bcolor=${red}
    else
      bicon="󰁹"; bcolor=${text}
    fi
    sketchybar --set battery icon="$bicon" icon.color="$bcolor" label="$(printf '%-4s' "''${pct}%")"

    # Leistung
    if [ -n "$watts" ]; then
      sketchybar --set battery_power drawing=on label="$(printf '%-4s' "''${watts}W")"
    else
      sketchybar --set battery_power drawing=off
    fi

    # Restzeit "Hh Mm" mit Suffix
    if [ -n "$tm" ] && [ "$tm" != "0:00" ]; then
      h="''${tm%%:*}"; m="''${tm##*:}"
      if [ "$h" = 0 ]; then ttxt="''${m}m"; else ttxt="''${h}h ''${m}m"; fi
      if [ "$charging" = 1 ]; then ttxt="''${ttxt} bis voll"; else ttxt="''${ttxt} übrig"; fi
      sketchybar --set battery_time drawing=on label="$ttxt"
    else
      sketchybar --set battery_time drawing=off
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
    d="$(human $drx)/s"; u="$(human $dtx)/s"
    sketchybar --set net_down label="$(printf '%-6s' "$d")" \
               --set net_up   label="$(printf '%-6s' "$u")"
  '';

  # HW-Provider: EIN macmon-pipe-Prozess speist alle HW-Items (sudo-frei).
  hwProvider = pkgs.writeShellScript "sb-hw-provider" ''
    ${macmon} pipe -i 2000 | while read -r line; do
      vals="$(printf '%s' "$line" | ${jq} -r '
        [ (.sys_power | round),
          (((.ecpu_usage[1] + .pcpu_usage[1]) / 2 * 100) | floor),
          ((.cpu_power * 10 | round) / 10),
          (.temp.cpu_temp_avg | floor),
          ((.gpu_usage[1] * 100) | floor),
          ((.gpu_power * 10 | round) / 10),
          (.temp.gpu_temp_avg | floor),
          ((.memory.ram_usage / 1073741824 * 10 | round) / 10)
        ] | @tsv')"
      IFS=$'\t' read -r tp cu cp ct gu gp gt mem <<< "$vals"
      # Rechtsbuendig auf feste Breite (Monospace) -> Island springt nicht,
      # wenn ein Wert von 1 auf 2 Stellen wechselt (quickshell valueChars-Aequivalent).
      sketchybar --set total_power label="$(printf '%-4s' "''${tp}W")" \
                 --set cpu_usage label="$(printf '%-4s' "''${cu}%")" \
                 --set cpu_power label="$(printf '%-5s' "''${cp}W")" \
                 --set cpu_temp  label="$(printf '%-4s' "''${ct}°")" \
                 --set gpu_usage label="$(printf '%-4s' "''${gu}%")" \
                 --set gpu_power label="$(printf '%-5s' "''${gp}W")" \
                 --set gpu_temp  label="$(printf '%-4s' "''${gt}°")" \
                 --set mem       label="$(printf '%-5s' "''${mem}G")"
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
        height=38 position=top color=0x00000000 \
        padding_left=12 padding_right=12 y_offset=6 sticky=on blur_radius=0

      sketchybar --default \
        icon.font="${font}:Bold:12.0" icon.color=${text} \
        label.font="${font}:Bold:11.0" label.color=${text} \
        padding_left=4 padding_right=4 \
        label.padding_left=4 label.padding_right=5 \
        icon.padding_left=8 icon.padding_right=4 \
        background.color=0x00000000

      # ── LINKS: Metrics-Island (macmon-gespeist, mit Separatoren) ──
      # Separator-Item-Stil: duenne "│"-Linie in surface1.
      add_sep() {
        sketchybar --add item "$1" left \
          --set "$1" label="│" label.color=${surface1} label.font="${font}:Regular:13.0" \
            icon.drawing=off background.drawing=off padding_left=4 padding_right=4
      }

      sketchybar --add item total_power left \
        --set total_power icon="󱐋" icon.color=${red} label="…"
      add_sep sep1
      sketchybar --add item cpu_usage left --set cpu_usage icon="󰻠" icon.color=${green}  label="…" \
        --add item cpu_power left --set cpu_power icon="󱐋" icon.color=${peach}  label="…" \
        --add item cpu_temp  left --set cpu_temp  icon="󰔏" icon.color=${yellow} label="…"
      add_sep sep2
      sketchybar --add item gpu_usage left --set gpu_usage icon="󰢮" icon.color=${teal}   label="…" \
        --add item gpu_power left --set gpu_power icon="󱐋" icon.color=${peach}  label="…" \
        --add item gpu_temp  left --set gpu_temp  icon="󰔏" icon.color=${yellow} label="…"
      add_sep sep3
      sketchybar --add item mem left --set mem icon="󰍛" icon.color=${mauve} label="…"
      add_sep sep4
      sketchybar --add item net_down left --set net_down icon="󰁆" icon.color=${blue}     label="…" \
        --add item net_up   left --set net_up   icon="󰁞" icon.color=${sapphire} label="…" \
          script="${netScript}" update_freq=3

      sketchybar --add bracket metrics \
        total_power sep1 cpu_usage cpu_power cpu_temp sep2 gpu_usage gpu_power gpu_temp sep3 mem sep4 net_down net_up \
        --set metrics ${island}

      # ── RECHTS: System-Island (wifi volume battery [power] [time] clock) ──
      sketchybar --add item clock right \
        --set clock icon="󰃰" icon.color=${pink} update_freq=10 script="${clockScript}"
      sketchybar --add item battery_time right \
        --set battery_time icon.drawing=off label.color=${subtext0} \
          label.font="${font}:Bold:10.0" drawing=off
      sketchybar --add item battery_power right \
        --set battery_power icon.drawing=off label.color=${peach} drawing=off
      sketchybar --add item battery right \
        --set battery update_freq=15 script="${batteryScript}" \
        --subscribe battery power_source_change system_woke
      sketchybar --add item volume right \
        --set volume icon="󰕾" icon.color=${sky} script="${volumeScript}" \
        --subscribe volume volume_change
      sketchybar --add item wifi right \
        --set wifi icon="󰖩" label.max_chars=18 update_freq=30 script="${wifiScript}"
      sketchybar --add bracket system \
        clock battery_time battery_power battery volume wifi --set system ${island}

      # ── HW-Provider starten (single instance) ──
      pkill -f sb-hw-provider 2>/dev/null || true
      nohup ${hwProvider} >/dev/null 2>&1 &

      sketchybar --update
    '';
  };
}
