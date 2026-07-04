{ ... }:
let
  # Nerd-Font-Glyphen als Escapes (gleiches Muster wie starship.nix), damit
  # die unsichtbaren Private-Use-Zeichen bei Editor-/Copy-Roundtrips nicht
  # verloren gehen. Codepoints > U+FFFF brauchen JSON-Surrogate-Paare.
  sepLeft     = builtins.fromJSON ''"\ue0b2"'';        # Powerline-Pfeil links
  sepRight    = builtins.fromJSON ''"\ue0b0"'';        # Powerline-Pfeil rechts
  iconApp     = builtins.fromJSON ''"\uf1ae"'';        # Application
  iconDir     = builtins.fromJSON ''"\uf07b"'';        # Ordner
  iconHost    = builtins.fromJSON ''"\udb81\udc8b"''; # Host (U+F048B, Surrogate-Paar)
  iconSession = builtins.fromJSON ''"\ue795"'';        # Session/Terminal
  iconClock   = builtins.fromJSON ''"\udb80\udcf0"''; # Datum/Uhrzeit (U+F00F0, Surrogate-Paar)
in
{
  programs.tmux = {
    enable = true;

    mouse = true;
    historyLimit = 50000;
    keyMode = "vi";
    terminal = "tmux-256color";

    # Ersetzt das tmux-sensible-Plugin (lief vorher via TPM). HM lädt es am
    # Anfang der Config; die Werte darunter würden sensible sonst wieder
    # überschreiben, deshalb explizit auf die sensible-/tmux-Defaults gesetzt.
    sensibleOnTop = true;
    escapeTime = 0;
    focusEvents = true;
    aggressiveResize = true;
    clock24 = true;

    # Landet NACH dem Plugin-Load in der tmux.conf — nötig, weil die
    # @thm_*-Variablen erst existieren, nachdem das Catppuccin-Plugin lief.
    extraConfig = ''
      set -ga terminal-overrides ",xterm-kitty:Tc"
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # Klick auf einen Session-Namen in der Statusbar -> zu dieser Session
      # wechseln. Die Namen sind via #[range=user|<session>] in
      # @catppuccin_session_text markiert; bei range=user liefert
      # mouse_status_range den Session-Namen, bei Fenstern die Konstante
      # "window" (dann Default-Verhalten select-window).
      bind -n MouseDown1Status {
        if -F "#{==:#{mouse_status_range},window}" {
          select-window -t=
        } {
          if -F "#{mouse_status_range}" {
            switch-client -t "#{mouse_status_range}"
          }
        }
      }

      # ── Status-Bar nach dem Plugin zusammensetzen ──────────────────
      # Bunte Modul-Farben (Mocha) — mit -F für Format-Expansion
      set -gF @catppuccin_session_color "#{E:@thm_teal}"
      set -gF @catppuccin_application_color "#{E:@thm_blue}"
      set -gF @catppuccin_directory_color "#{E:@thm_yellow}"
      set -gF @catppuccin_host_color "#{E:@thm_green}"
      set -gF @catppuccin_date_time_color "#{E:@thm_mauve}"

      set -g status-left-length 100
      set -g status-right-length 100

      set -g status-left ""
      # Maskiere den linken Separator vom Session-Block, indem wir bg auf teal forcieren
      set -ag status-left "#[bg=#{E:@thm_teal}]#{E:@catppuccin_status_session}"

      set -g status-right ""
      set -ag status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_directory}"
      set -ag status-right "#{E:@catppuccin_status_host}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"
    '';
  };

  # Das Plugin selbst kommt über catppuccin.autoEnable (theming.nix); flavor
  # setzt das Modul aus catppuccin.flavor. Dieser Block landet VOR dem
  # run-shell des Plugins — dort müssen die @catppuccin_*-Optionen stehen.
  catppuccin.tmux.extraConfig = ''
    # ── Catppuccin Mocha Teal Powerline ─────────────────────────────
    # Pfeil-Separatoren (slanted = klassischer Powerline-Pfeil)
    set -g @catppuccin_window_status_style 'slanted'

    # Aktives Fenster: Teal-Hintergrund als Akzent
    set -g @catppuccin_window_current_background "#{@thm_teal}"

    # Datumsformat: Wochentag + Tag.Monat + Uhrzeit
    set -g @catppuccin_date_time_text    "  %a %d.%m %H:%M "

    # Directory im Statusbar zeigt basename des Pane-Pfads
    set -g @catppuccin_directory_text "  #{b:pane_current_path} "

    # Extra Padding für Module
    set -g @catppuccin_application_text  "  #{pane_current_command} "
    set -g @catppuccin_host_text         "  #H "
    # Alle Sessions des tmux-Servers auflisten (nicht nur die aktuelle): der
    # native #{S:...}-Loop iteriert ueber alle Sessions. Die aktive/attachte
    # Session teal + fett, die uebrigen gedimmt.
    set -g @catppuccin_session_text      "  #{S:#[range=user|#{session_name}]#{?session_attached,#[fg=#{E:@thm_teal}]#[bold]#{session_name}#[nobold],#[fg=#{E:@thm_overlay_1}]#{session_name}}#[fg=#{E:@thm_fg}]#[norange] }"
    set -g @catppuccin_window_default_text  "  #W "
    set -g @catppuccin_window_current_text  "  #W "

    # Powerline-Pfeil-Separatoren zwischen den Status-Modulen
    set -g @catppuccin_status_left_separator  "${sepLeft}"
    set -g @catppuccin_status_right_separator "${sepRight}"
    set -g @catppuccin_status_connect_separator "yes"
    set -g @catppuccin_status_fill "all"

    # Mehr Padding für Icons in den Modul-Boxen
    set -g @catppuccin_application_icon  " ${iconApp} "
    set -g @catppuccin_directory_icon    " ${iconDir} "
    set -g @catppuccin_host_icon         " ${iconHost} "
    set -g @catppuccin_session_icon      " ${iconSession} "
    set -g @catppuccin_date_time_icon    " ${iconClock} "
  '';
}
