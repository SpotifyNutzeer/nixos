{ ... }:
{
  programs.aerospace = {
    enable = true;
    # home-manager verwaltet den launchd-Autostart (kein manuelles start-at-login).
    launchd.enable = true;

    settings = {
      # Kein eigenes Login-Item — macht launchd (s.o.).
      start-at-login = false;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Gaps analog Hyprland (gaps_in=5, gaps_out=10).
      gaps = {
        inner.horizontal = 5;
        inner.vertical = 5;
        outer.left = 10;
        outer.right = 10;
        outer.top = 10;
        outer.bottom = 10;
      };

      # Modifier = Alt (⌥), 1:1 zu den SUPER-Bindings unter Hyprland.
      mode.main.binding = {
        # Programme / Fenster
        alt-enter = "exec-and-forget open -na kitty";
        alt-shift-q = "close";
        alt-f = "fullscreen";
        alt-v = "layout floating tiling";
        alt-j = "layout tiles horizontal vertical";
        alt-e = "exec-and-forget open -a Finder";

        # Launcher (MVP: Raycast per URL-Scheme; Phase 2 -> Sol/Ueli)
        alt-shift-enter = "exec-and-forget open raycast://";

        # Fokus bewegen
        alt-left = "focus left";
        alt-right = "focus right";
        alt-up = "focus up";
        alt-down = "focus down";

        # Workspaces wechseln (1..10)
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # Fenster in Workspace verschieben (1..10)
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";
      };
    };
  };
}
