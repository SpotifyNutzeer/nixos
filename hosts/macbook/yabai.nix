{ config, pkgs, ... }:
let
  # yabai binary with its full path so skhd finds it reliably
  # (skhd launches commands via sh without the full user PATH).
  yabai = "${config.services.yabai.package}/bin/yabai";
in
{
  # ── yabai: tiling WM with real BSP (= dwindle) ──────────────────────────────
  services.yabai = {
    enable = true;
    # Scripting Addition: needed for space control (focus/move/create).
    # Sets the passwordless sudoers rule for `sudo yabai --load-sa`.
    # Requires partially disabled SIP (see hosts/macbook/README.md).
    enableScriptingAddition = true;

    config = {
      layout = "bsp";

      # Gaps matching Hyprland (gaps_in=5 -> window_gap, gaps_out=10 -> padding).
      window_gap = 10;
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;

      split_ratio = 0.5;
      auto_balance = "off";
      window_placement = "second_child";

      # Hyprland input.follow_mouse=1 -> focus follows mouse (without raise).
      focus_follows_mouse = "autofocus";
      mouse_follows_focus = "off";

      # Hyprland bindm (Super+LMB move / Super+RMB resize) -> Alt here.
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
    };

    extraConfig = ''
      # Load the Scripting Addition (and reload it automatically after a Dock restart).
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      sudo yabai --load-sa

      # Make sure 10 spaces exist (for alt-1..10). Idempotent: only creates
      # as many as needed to reach 10 (with >=10 nothing happens).
      space_count=$(yabai -m query --spaces | ${pkgs.jq}/bin/jq length)
      while [ "$space_count" -lt 10 ]; do
        yabai -m space --create
        space_count=$((space_count + 1))
      done
    '';
  };

  # ── skhd: hotkey daemon (yabai does no key binding itself) ──────────────────
  # Modifier = ONLY the left Option key (lalt), 1:1 with the Hyprland SUPER
  # bindings. The right Option key stays free for special characters of the
  # German layout (| \ [ ] { } @ ~ € all live on Option) — like AltGr on Linux.
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # ── Programs / windows ──────────────────────────────────
      # --single-instance: new windows run inside the existing kitty instance
      # (one process, one Dock icon) instead of a separate app instance per window.
      lalt - return          : open -na kitty --args --single-instance
      # yabai --close presses the AX close button — kitty does not have one
      # due to hide_window_decorations. For kitty, pass the key through (~);
      # there a native keybinding (close_os_window) closes the window.
      lalt + shift - q [
          "kitty" ~
          *       : ${yabai} -m window --close
      ]
      lalt - f               : ${yabai} -m window --toggle zoom-fullscreen
      lalt - v               : ${yabai} -m window --toggle float
      lalt - j               : ${yabai} -m window --toggle split
      lalt - e               : open -a Finder

      # Launcher: Raycast via URL scheme (= Hyprland $menu)
      lalt + shift - return  : open raycast://

      # ── Move focus ──────────────────────────────────────────
      lalt - left            : ${yabai} -m window --focus west
      lalt - right           : ${yabai} -m window --focus east
      lalt - up              : ${yabai} -m window --focus north
      lalt - down            : ${yabai} -m window --focus south

      # ── Switch workspaces (spaces) 1..10 ────────────────────
      lalt - 1 : ${yabai} -m space --focus 1
      lalt - 2 : ${yabai} -m space --focus 2
      lalt - 3 : ${yabai} -m space --focus 3
      lalt - 4 : ${yabai} -m space --focus 4
      lalt - 5 : ${yabai} -m space --focus 5
      lalt - 6 : ${yabai} -m space --focus 6
      lalt - 7 : ${yabai} -m space --focus 7
      lalt - 8 : ${yabai} -m space --focus 8
      lalt - 9 : ${yabai} -m space --focus 9
      lalt - 0 : ${yabai} -m space --focus 10

      # ── Move window to space 1..10 (focus stays) ────────────
      lalt + shift - 1 : ${yabai} -m window --space 1
      lalt + shift - 2 : ${yabai} -m window --space 2
      lalt + shift - 3 : ${yabai} -m window --space 3
      lalt + shift - 4 : ${yabai} -m window --space 4
      lalt + shift - 5 : ${yabai} -m window --space 5
      lalt + shift - 6 : ${yabai} -m window --space 6
      lalt + shift - 7 : ${yabai} -m window --space 7
      lalt + shift - 8 : ${yabai} -m window --space 8
      lalt + shift - 9 : ${yabai} -m window --space 9
      lalt + shift - 0 : ${yabai} -m window --space 10
    '';
  };

  # skhd does NOT reload its config when darwin-rebuild only swaps the symlink
  # target of /etc/skhdrc — from skhd's point of view the watched path never
  # changes, and the launchd plist (and with it the service) stays unchanged.
  # Therefore restart it explicitly after every activation.
  system.activationScripts.postActivation.text = ''
    echo "restarting skhd (config lives in /etc/skhdrc, plist never changes)..."
    launchctl kickstart -k "gui/$(id -u ${config.system.primaryUser})/org.nixos.skhd" || true
  '';

  # ── JankyBorders: active window border (replaces Hyprland's gradient border) ──
  services.jankyborders = {
    enable = true;
    # HiDPI: without this the border renders at 1x on the Retina display -> looks
    # very thin and breaks at the rounded corners. With hidpi=true it renders
    # natively (sharp, clean corners).
    hidpi = true;
    width = 2.0;                       # Hyprland border_size = 2 (sharp with hidpi)
    style = "round";                   # rounded corners matching Hyprland rounding
    order = "above";                   # border above the window -> corners visible
    # Hyprland: col.active_border = $sky $teal 45deg ($sky=89dceb, $teal=94e2d5)
    active_color = "gradient(top_left=0xff89dceb,bottom_right=0xff94e2d5)";
    # Hyprland: col.inactive_border = rgba(45475aaa)
    inactive_color = "0xaa45475a";
  };
}
