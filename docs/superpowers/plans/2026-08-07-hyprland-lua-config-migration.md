# Hyprland Lua Config Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Hyprland configuration from the deprecated hyprlang (`.conf`) format to the Lua format, so the setup keeps working when Hyprland 0.57 drops `.conf` support.

**Architecture:** Hybrid. Declarative blocks that map cleanly onto Nix attrsets (`hl.config`, `hl.monitor`, `hl.window_rule`, `hl.layer_rule`, `hl.workspace_rule`, `hl.gesture`, `hl.device`) stay in `wayland.windowManager.hyprland.settings` — Home Manager renders each attribute `name` as an `hl.<name>(...)` call. Imperative blocks that read badly through the Nix→Lua escaping layer (keybinds, animation curves, autostart) become real Lua files shipped via `extraLuaFiles`. Host-specific monitor/workspace modules keep their current shape and only change field names.

**Tech Stack:** NixOS + Home Manager (`nix-community/home-manager`, rev `7834e825`), Hyprland 0.56.1, Lua 5.x (Hyprland-embedded), Quickshell/QML for the runtime theme switcher.

## Global Constraints

- Hyprland version in the flake is **0.56.1**. Both config formats work in 0.56 — this is what makes the migration testable and reversible. Do not bump Hyprland as part of this migration.
- New comments, docs, and commit messages in the `nixos` repo are **English** (repo convention since 2026-08-04).
- `wayland.windowManager.hyprland.systemd.enable` **must stay `false`**. The session is managed by uwsm; enabling it re-triggers the login loop documented in `home/program-configs/linux/hyprland.nix:9-13`.
- `uwsm finalize` **must be the first command** in the `hyprland.start` hook. The `wayland-wm@hyprland.service` unit hangs in its activation timeout otherwise.
- Session environment stays in `xdg.configFile."uwsm/env-hyprland"`. Do **not** move it into `hl.env(...)` — the reasoning in `hyprland.nix:29-32` (D-Bus/systemd scopes vs. compositor children) is unchanged by this migration.
- The migration spans **two repos**: `/home/paul/git/nixos` and `/home/paul/git/dotfiles` (consumed as flake input `dotfiles`, `github:paul-wtf/dotfiles`, `flake = false`).
- Every change is validated with `nixos-rebuild build --flake .#<host>` (build only, **no `sudo`** — building needs no root) before any `switch`. Only the `switch` steps in Tasks 4-6 use `sudo`; run it directly, a GUI dialog prompts the user for the password.
- Work happens on the `hyprland-lua-migration` branch, not `master`.

---

## Background: verified facts

All of the following were verified against Hyprland 0.56.1 (`/nix/store/k1ayp5jzyvjkgicb896zrbh0vqbyp70c-hyprland-0.56.1`) and its sources (`/nix/store/yls1h22774lz4jvx2w6mzrbi64lck59j-source`). Do not re-derive.

**The deprecation is real.** String in the binary:
```
You are using the .conf config format, support for which will be removed in Hyprland 0.57.
```

**Config discovery.** Hyprland prefers `~/.config/hypr/hyprland.lua` and only falls back to `hyprland.conf`:
```
[cfg] Using lua config found at {}
[cfg] Lua config not found, using legacy config at {}
```
This means rollback is trivial: whichever file HM writes wins.

**Reference material shipped with the package:**
- `$hyprland/share/hypr/hyprland.lua` — upstream default config in Lua. It is the same template the current `.conf` config descends from (same bezier curves, same `fix-xwayland-drags` rule, even the same `move-hyprland-run` rule). Use it as the primary reference.
- `$hyprland/share/hypr/stubs/hl.meta.lua` — 1770 lines of LSP stubs with the full API surface, all `hl.config` keys, and all event names.

**Home Manager already supports this.** `configType` is an enum of `[ "hyprlang" "lua" ]`; the default for stateVersion ≥ 26.05 is already `"lua"`. In Lua mode HM renders:
- `settings.<name> = value` → `hl.<name>(<value>)`
- `settings.<name> = [ a b ]` → one `hl.<name>(...)` call per element
- `extraLuaFiles.<name>` → `$XDG_CONFIG_HOME/hypr/<name>.lua`, auto-`require`d
- HM also writes `hypr/.luarc.json` for the Lua language server when `configType = "lua"`.

**Generated file ordering** (from `modules/services/window-managers/hyprland/lib.nix`, `luaConfig`):
`plugins` → `extraLuaFiles` requires → `settings` → `submaps` → start hook → shutdown hook → `extraConfig`.
This is why animation curves must not depend on `settings` having run: `extraLuaFiles` are required *before* the `hl.config(...)` calls from `settings`.

**BLOCKER — `hyprctl keyword` stops working.** `src/debug/HyprCtl.cpp:1162-1163`:
```cpp
if (Config::mgr()->type() != Config::CONFIG_LEGACY)
    return "keyword can't work with non-legacy parsers. Use eval.";
```
`dotfiles/.config/quickshell/Theme.qml:165` drives the zen/mocha/liquidglass theme switch with `hyprctl --batch keyword ...`. **It will silently break.** The replacement is `hyprctl eval '<lua>'`, which is Lua-only (`evalRequest`, same file). Task 6 covers this.

`hyprctl getoption` keeps working in both modes (`dispatchGetOption` goes through `Config::mgr()->getConfigValue`, not the legacy parser).

**Verified dispatcher signatures** (from `src/config/lua/bindings/LuaBindingsDispatchers.cpp`):

| hyprlang | Lua |
|---|---|
| `exec` | `hl.dsp.exec_cmd(str)` — still spawned via the same executor, so `a; b` shell chains keep working |
| `killactive` | `hl.dsp.window.close()` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen` | `hl.dsp.window.fullscreen()` — optional `{ mode = "fullscreen"\|"maximized", action = "toggle"\|"set"\|"unset", layout_aware = bool }` |
| `pseudo` | `hl.dsp.window.pseudo()` |
| `layoutmsg, <msg>` | `hl.dsp.layout("<msg>")` |
| `movefocus, l` | `hl.dsp.focus({ direction = "left" })` |
| `workspace, N` | `hl.dsp.focus({ workspace = N })` |
| `movetoworkspace, N` | `hl.dsp.window.move({ workspace = N })` |
| `togglespecialworkspace, magic` | `hl.dsp.workspace.toggle_special("magic")` |
| `movewindow` (bindm) | `hl.dsp.window.drag()` + `{ mouse = true }` |
| `resizewindow` (bindm) | `hl.dsp.window.resize()` + `{ mouse = true }` |
| `exit` | `hl.dsp.exit()` |

**Bind option flags** (`HL.BindOptions`): `bindm` → `{ mouse = true }`, `bindl` → `{ locked = true }`, `bindel` → `{ locked = true, repeating = true }`, `binde` → `{ repeating = true }`.

**Type aliases** (`hl.meta.lua:393-398`):
```
HL.CssGap  = integer | {top?, right?, bottom?, left?}
HL.Gradient = string | {colors: string[], angle?: number}
```

**Window rule fields** are passed through generically to the same rule engine as hyprlang v3 rules (`hlWindowRule` in `LuaBindingsConfigRules.cpp:1167`). Only `name`, `enabled`, and `match` are special-cased. So `size`, `center`, `suppress_event`, `no_focus`, `move`, `float`, `workspace`, `monitor`, `fullscreen` keep their current names — they just move out of the `"match:*"` string-key style into a nested `match = { ... }` table.

---

## File Structure

| File | Responsibility |
|---|---|
| `home/program-configs/linux/hyprland.nix` (modify) | HM module. `configType = "lua"`, colour `let`-bindings, the declarative `settings` attrset (`config`, `window_rule`, `layer_rule`, `gesture`, `device`), `extraLuaFiles` wiring, the autostart Lua (inline text — needs `${dotfiles}` interpolation), and the unchanged uwsm env file. |
| `home/program-configs/linux/hypr/binds.lua` (create) | All keybinds as real Lua. Pure — no Nix interpolation, so it ships as a path. |
| `home/program-configs/linux/hypr/animations.lua` (create) | `animations.enabled`, all `hl.curve` definitions, all `hl.animation` calls. Self-contained so it does not depend on `settings` ordering. |
| `hosts/desktop/hyprland-monitors.nix` (modify) | `monitorv2` → `monitor`, `workspace` strings → `workspace_rule` attrsets. Structure otherwise unchanged. |
| `hosts/laptop/hyprland-monitors.nix` (modify) | `monitorv2` → `monitor`. |
| `dotfiles/.config/quickshell/Theme.qml` (modify) | Theme switcher: `hyprctl --batch keyword ...` → `hyprctl eval '<lua>'`. |
| `flake.nix` / `flake.lock` (modify) | Bump the `dotfiles` input after the Theme.qml change is pushed. |

Not touched: `home/program-configs/linux/hyprlock.nix` (hyprlock is a separate project with its own hyprlang parser — this deprecation does not apply to it), `common/desktop.nix`, `xdg.configFile."uwsm/env-hyprland"`.

---

### Task 1: Keybinds as a standalone Lua file

This task lands `binds.lua` and wires it in, while the rest of the config stays hyprlang. That is not a working state on its own — so this task also flips `configType` and moves the `hl.config` block over. It is the first reviewable unit: after it, the session is fully Lua-driven for config + binds.

**Files:**
- Create: `home/program-configs/linux/hypr/binds.lua`
- Create: `home/program-configs/linux/hypr/animations.lua`
- Modify: `home/program-configs/linux/hyprland.nix` (whole `settings` block, lines 15-263)
- Test: manual — `nixos-rebuild build` + inspection of the generated `hyprland.lua`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `home/program-configs/linux/hypr/binds.lua` and `animations.lua`, both auto-`require`d by HM via `extraLuaFiles`. The colour values `sky = "rgb(89dceb)"` and `teal = "rgb(94e2d5)"` become Nix `let`-bindings in `hyprland.nix` and are consumed by Task 6's theme switcher as literal strings.

- [ ] **Step 1: Create the binds file**

Create `home/program-configs/linux/hypr/binds.lua`:

```lua
-- Keybinds. Required automatically by the Home Manager Hyprland module via
-- extraLuaFiles, so this file runs before the hl.config(...) calls generated
-- from `settings`. Nothing here depends on config values at load time.

local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun"
local screenshot  = "grimblast -f -n copy area"

hl.bind(mainMod .. " + RETURN",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E",      hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))

-- Toggle layout dwindle <-> scrolling. Native now: `hyprctl keyword` no longer
-- works under the Lua config manager, and hl.get_config/hl.config do the same
-- job in-process without shelling out.
hl.bind(mainMod .. " + TAB", function()
    local layout = hl.get_config("general.layout")
    hl.config({ general = { layout = layout == "scrolling" and "dwindle" or "scrolling" } })
end)

-- Scrolling layout. hl.dsp.layout only acts in the scrolling layout and is
-- harmless in dwindle.
hl.bind(mainMod .. " + period",         hl.dsp.layout("move +col"))     -- scroll the tape one column right
hl.bind(mainMod .. " + comma",          hl.dsp.layout("move -col"))     -- scroll the tape one column left
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))     -- swap active column with its right neighbour
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.layout("swapcol l"))     -- swap active column with its left neighbour
hl.bind(mainMod .. " + R",              hl.dsp.layout("colresize +conf")) -- cycle column width forward
hl.bind(mainMod .. " + SHIFT + R",      hl.dsp.layout("colresize -conf")) -- cycle column width backward
hl.bind(mainMod .. " + G",              hl.dsp.layout("fit visible"))   -- fit all visible columns
hl.bind(mainMod .. " + M",              hl.dsp.layout("fit expand"))    -- let the active window fill free space
hl.bind(mainMod .. " + C",              hl.dsp.layout("consume"))       -- suck the window into the previous column
hl.bind(mainMod .. " + X",              hl.dsp.layout("expel"))         -- detach the window into its own column
hl.bind(mainMod .. " + U",              hl.dsp.layout("promote"))       -- promote the window into a new column

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.config/quickshell/scripts/theme-switch.sh menu"))
hl.bind(mainMod .. " + ALT + R",   hl.dsp.exec_cmd("killall -SIGUSR1 gpu-screen-recorder"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-10; key 0 maps to workspace 10.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",          hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + CTRL + S",   hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Former bindel: locked + repeating
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Former bindl: locked, requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
```

- [ ] **Step 2: Create the animations file**

Create `home/program-configs/linux/hypr/animations.lua`. `animations.enabled` lives here rather than in `settings` so this file is order-independent — `extraLuaFiles` are required before the `hl.config(...)` calls generated from `settings`.

```lua
-- Animation curves and animations. Self-contained: animations.enabled is set
-- here rather than in `settings`, because extraLuaFiles are required BEFORE the
-- hl.config(...) calls that Home Manager generates from `settings`.

hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 60,   bezier = "linear",       style = "loop" })
hl.animation({ leaf = "glowangle",     enabled = true, speed = 60,   bezier = "linear",       style = "loop" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
```

- [ ] **Step 3: Rewrite the Home Manager module**

Replace the whole of `home/program-configs/linux/hyprland.nix` with:

```nix
{ pkgs, dotfiles, ... }:
let
  # Only the colours hyprland.lua actually uses; the full palette moves into the
  # shared module later. Quickshell's Theme.qml hardcodes the same literals in
  # its hyprctl eval payload -- keep them in sync.
  #
  # Stored as bare hex so the opaque and the translucent form of a colour cannot
  # drift apart: the glow gradient is the same sky/teal at 40% alpha.
  sky   = "89dceb";
  teal  = "94e2d5";
  crust = "11111b";
  surface = "45475a";

  rgb  = hex: "rgb(${hex})";
  rgba = hex: alpha: "rgba(${hex}${alpha})";
in
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

    # Hyprland 0.57 removes the .conf format. 0.56 still accepts both, and
    # Hyprland prefers hyprland.lua whenever it exists -- so flipping this back
    # to "hyprlang" is a complete rollback.
    configType = "lua";

    # NOTE: Session env lives in ~/.config/uwsm/env-hyprland (see below).
    # An hl.env block would only inherit to direct exec_cmd children, not to
    # `uwsm app` scopes or D-Bus services. UWSM loads the uwsm env file into the
    # systemd user environment before the compositor -> all inherit consistently.

    extraLuaFiles = {
      binds = ./hypr/binds.lua;
      animations = ./hypr/animations.lua;

      # Autostart lives here rather than in a plain .lua file because it needs
      # the ${dotfiles} store path interpolated.
      autostart = ''
        hl.on("hyprland.start", function()
            -- UWSM readiness: signals to wayland-wm@hyprland.service that the
            -- compositor is up. Exports WAYLAND_DISPLAY/DISPLAY into the systemd
            -- user and D-Bus environment and activates graphical-session.target.
            -- MUST run first, otherwise the session unit hangs in the activating
            -- timeout.
            hl.exec_cmd("uwsm finalize")

            -- GUI apps via `uwsm app --`: they land in their own systemd scopes
            -- (app.slice) instead of as children of the compositor -> clean
            -- stopping at session end, own cgroup/OOM limits, correct placement
            -- in the session tree.
            hl.exec_cmd("uwsm app -- quickshell")
            hl.exec_cmd("uwsm app -- discord")

            -- Spotify (Chromium/CEF) prefers PulseAudio but falls back to ALSA
            -- if it gets no connection to pipewire-pulse at startup.
            -- pipewire-pulse.service is socket-activated (Type=simple): the socket
            -- is there early, but the service only starts COLD on the first client
            -- connect. At boot, Spotify's connect triggers this cold start, whose
            -- latency runs into Chromium's Pulse handshake timeout -> ALSA
            -- fallback. Depending on backend, the client registers with WirePlumber
            -- under a different identity, which makes the target set in pavucontrol
            -- / via the pulse.rules get lost after a restart.
            -- Fix: explicitly warm-start pipewire-pulse BEFORE Spotify (systemctl
            -- start blocks until active) so that Spotify deterministically goes via
            -- PulseAudio and the pulse.rules rule (see hosts/desktop/pipewire.nix)
            -- takes effect.
            hl.exec_cmd("systemctl --user start pipewire-pulse.service; uwsm app -- spotify")

            hl.exec_cmd("uwsm app -- awww-daemon")
            hl.exec_cmd("sleep 1; awww img ${dotfiles}/wallpapers/firewatchcatpuccinmochagreen.png")
            hl.exec_cmd("uwsm app -- streamcontroller -b")
            hl.exec_cmd("uwsm app -- steam -silent")
            hl.exec_cmd("uwsm app -- gsr-ui")
            hl.exec_cmd("uwsm app -- Telegram -startintray")
            hl.exec_cmd("uwsm app -- seadrive-gui")
        end)
      '';
    };

    settings = {
      # Each attribute renders as an hl.<name>(...) call; list values render one
      # call per element.
      config = {
        general = {
          gaps_in = 5;
          # Defaults = zen variant (quickshell Theme.qml couples at runtime on
          # theme switch via `hyprctl eval`: zen -> these values,
          # mocha/liquidglass -> 10 / sky..teal 45deg / 10)
          gaps_out = { top = 12; right = 22; bottom = 22; left = 22; };
          border_size = 2;
          col = {
            active_border = rgb teal;
            inactive_border = rgba surface "aa";
          };
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 12;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = { enabled = true; range = 4; render_power = 3; color = rgba crust "ee"; };
          blur = { enabled = true; size = 6; passes = 2; vibrancy = 0.1696; new_optimizations = false; };
          motion_blur = { enabled = true; samples = 7; };
          # The look lives entirely here; Theme.qml only toggles enabled (zen ->
          # false, mocha/liquidglass -> true). Inactive windows transparent ->
          # focus indicator.
          glow = {
            enabled = false;
            range = 10;
            render_power = 3;
            color = { colors = [ (rgba sky "66") (rgba teal "66") ]; angle = 45; };
            color_inactive = rgba "000000" "00";
          };
        };

        dwindle = { preserve_split = true; };
        master = { new_status = "master"; };

        # Native scrolling layout (since Hyprland 0.51, usable here via toggle
        # SUPER+TAB).
        scrolling = {
          column_width = 0.5;                                # default width of new columns (0.1-1.0)
          focus_fit_method = 1;                              # fit the focused column instead of centering (0=center, 1=fit)
          explicit_column_widths = "0.333, 0.5, 0.667, 1.0"; # presets that colresize +conf/-conf cycles through
          # direction = "right";                             # direction in which new columns grow (left/right/down/up)
        };

        misc = { force_default_wallpaper = -1; disable_hyprland_logo = false; };

        render = {
          # use_shader_blur_blend = true;
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

        xwayland = { enabled = true; force_zero_scaling = true; };
      };

      gesture = [ { fingers = 3; direction = "horizontal"; action = "workspace"; } ];

      device = [ { name = "epic-mouse-v1"; sensitivity = -0.5; } ];

      layer_rule = [
        { name = "quickshell-blur"; match = { namespace = "quickshell"; }; blur = true; ignore_alpha = 0.05; }
      ];

      window_rule = [
        { name = "suppress-maximize-events"; match = { class = ".*"; }; suppress_event = "maximize"; }
        { name = "fix-xwayland-drags"; match = { class = "^$"; title = "^$"; xwayland = true; float = true; fullscreen = false; pin = false; }; no_focus = true; }
        { name = "move-hyprland-run"; match = { class = "hyprland-run"; }; move = "20 monitor_h-120"; float = true; }
        { name = "discord-position"; match = { class = "^discord$"; }; workspace = "2"; }
        { name = "spotify-position"; match = { class = "^spotify$"; }; workspace = "2"; }
        { name = "steam-bigpicture"; match = { class = "^steam$"; title = "^Steam Big Picture Mode$"; }; monitor = "HDMI-A-1"; fullscreen = true; }
        { name = "bitwarden-extension"; match = { class = "^brave-nngceckbapebfimnlniiiahkandclblb-Default$"; }; float = true; }
        { name = "thunar-file-operation-float"; match = { class = "^thunar$"; title = "^File Operation Progress$"; }; float = true; size = "600 300"; center = true; }
      ];
    };
  };

  # UWSM session environment: sourced BEFORE the compositor and loaded into the
  # systemd user + D-Bus activation environment. Thus reaches the compositor
  # itself, all `uwsm app` scopes and D-Bus-activated services (in contrast to an
  # hl.env block, which only reaches direct children). Single source of truth.
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
```

The `rgb`/`rgba` helpers exist so the opaque and translucent forms of the same colour cannot drift: `general.col.active_border` and the glow gradient must stay the same sky/teal. Task 6's theme-switch payload hardcodes the resulting literals on the Quickshell side — `rgb(89dceb)`, `rgb(94e2d5)` — because it lives in a different repo.

- [ ] **Step 4: Build (do not switch)**

`nixos-rebuild build` needs no root — it only realises the closure into `./result`. Do not use `sudo` here; that would pop a GUI password dialog at the user for no reason.

```bash
cd /home/paul/git/nixos && nixos-rebuild build --flake .#desktop
```
Expected: build succeeds.

Note that the build succeeding is a weak signal here. Home Manager renders any attribute name in `settings` as `hl.<name>(...)` without validating it, so the still-unported `monitorv2` from `hosts/desktop/hyprland-monitors.nix` becomes a bogus `hl.monitorv2(...)` call that only fails at Hyprland runtime. That is exactly what Task 2 fixes — do not switch until it is done.

- [ ] **Step 5: Commit**

```bash
cd /home/paul/git/nixos
git add home/program-configs/linux/hyprland.nix home/program-configs/linux/hypr/
git commit -m "hyprland: migrate config from hyprlang to Lua

Hyprland 0.57 removes the .conf format. Switch configType to lua and
split the config: declarative blocks stay in Nix settings (rendered as
hl.<name>(...) calls), binds/curves/autostart become real Lua files.

The SUPER+TAB layout toggle now uses hl.get_config/hl.config instead of
shelling out to hyprctl keyword, which no longer works under the Lua
config manager."
```

---

### Task 2: Host monitor and workspace modules

**Files:**
- Modify: `hosts/desktop/hyprland-monitors.nix`
- Modify: `hosts/laptop/hyprland-monitors.nix`
- Test: `nixos-rebuild build` for both hosts

**Interfaces:**
- Consumes: `configType = "lua"` from Task 1 — these modules only contribute to `wayland.windowManager.hyprland.settings`, so their attribute names must now be Lua function names.
- Produces: `hl.monitor(...)` calls per output and `hl.workspace_rule(...)` calls per workspace pin.

- [ ] **Step 1: Rewrite the desktop monitors module**

`hosts/desktop/hyprland-monitors.nix` — `monitorv2` becomes `monitor` (field names are unchanged; `HL.MonitorSpec` uses the same keys), and the `workspace` strings become `workspace_rule` attrsets:

```nix
{ ... }:
let
  # Shared HDR pipeline settings for both HDR-capable monitors (the laptop
  # panel in hosts/laptop/hyprland-monitors.nix uses the same values).
  hdr = {
    bitdepth = 10; cm = "hdredid";
    sdr_min_luminance = 0.005; sdr_max_luminance = 250;
    min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22";
  };
in
{
  # Desktop-specific monitors + workspace assignment (pulled out of the shared
  # hyprland.nix; the laptop has its own counterpart).
  wayland.windowManager.hyprland.settings = {
    monitor = [
      ({
        output = "HDMI-A-1"; mode = "3840x2160@240.00"; position = "0x1440";
        scale = "1.0"; vrr = 2;
      } // hdr)
      ({
        output = "DP-2"; mode = "3440x1440@164.90"; position = "0x0";
        vrr = 2;
      } // hdr)
      { output = "DP-3"; mode = "2560x720@60"; position = "0x3600"; scale = "1.0"; }
    ];

    workspace_rule = [
      { workspace = "1"; monitor = "HDMI-A-1"; }
      { workspace = "2"; monitor = "DP-3"; }
      { workspace = "3"; monitor = "DP-2"; }
    ];
  };
}
```

- [ ] **Step 2: Rewrite the laptop monitors module**

`hosts/laptop/hyprland-monitors.nix`:

```nix
{ ... }:
{
  # Internal display; counterpart to hosts/desktop/hyprland-monitors.nix.
  wayland.windowManager.hyprland.settings.monitor = [
    {
      output = "eDP-1"; mode = "1920x1200@60"; position = "0x0";
      scale = "1.0"; bitdepth = 10; cm = "hdredid";
      sdr_min_luminance = 0.005; sdr_max_luminance = 250;
      min_luminance = 0; max_luminance = 1000; sdr_eotf = "gamma22";
    }
  ];
}
```

- [ ] **Step 3: Build both hosts**

```bash
cd /home/paul/git/nixos
nixos-rebuild build --flake .#desktop && nixos-rebuild build --flake .#laptop
```
Expected: both succeed. No `sudo` — building needs no root.

- [ ] **Step 4: Commit**

```bash
cd /home/paul/git/nixos
git add hosts/desktop/hyprland-monitors.nix hosts/laptop/hyprland-monitors.nix
git commit -m "hyprland: port host monitor modules to the Lua config

monitorv2 -> monitor (same field names, now hl.monitor calls) and the
workspace pin strings become hl.workspace_rule attrsets."
```

---

### Task 3: Inspect the generated Lua before switching

The generated file is the actual deliverable of Tasks 1-2. Read it before putting it in front of a login.

**Files:**
- Test: read-only inspection of the build result

**Interfaces:**
- Consumes: the `result` symlink produced by Task 2's build.
- Produces: a verified `hyprland.lua`; no repo changes.

- [ ] **Step 1: Locate and read the generated config**

```bash
cd /home/paul/git/nixos
nixos-rebuild build --flake .#desktop
find "$(readlink -f result)" -name 'hyprland.lua' 2>/dev/null | head -1
```
If that path is not resolvable through the system closure, extract it from the Home Manager files derivation instead:
```bash
nix eval --raw .#nixosConfigurations.desktop.config.home-manager.users.paul.xdg.configFile."hypr/hyprland.lua".source
```
Read the resulting file end to end.

- [ ] **Step 2: Check it against this list**

- [ ] File starts with `-- Generated by Home Manager.`
- [ ] `require("animations")`, `require("autostart")`, `require("binds")` all appear, before any `hl.config(...)` call.
- [ ] `hl.config({...})` contains `general`, `decoration`, `dwindle`, `master`, `scrolling`, `misc`, `render`, `input`, `xwayland`.
- [ ] `general.gaps_out` renders as a table `{ top = 12, right = 22, bottom = 22, left = 22 }`, not a string.
- [ ] `decoration.glow.color` renders as `{ colors = { "rgba(89dceb66)", "rgba(94e2d566)" }, angle = 45 }`.
- [ ] Exactly 8 `hl.window_rule(` calls, 1 `hl.layer_rule(`, 1 `hl.gesture(`, 1 `hl.device(`, 3 `hl.monitor(`, 3 `hl.workspace_rule(`.
- [ ] No leftover `$mainMod`, `$terminal`, `$sky`, `$teal`, `bindm`, `bindel`, `bindl`, `exec-once`, `monitorv2`, `windowrule`, or `layerrule` anywhere in the file.
- [ ] `uwsm finalize` is the first `hl.exec_cmd` inside the `hyprland.start` callback.

Count them:
```bash
f=<path from step 1>
grep -c 'hl.window_rule(' "$f"; grep -c 'hl.monitor(' "$f"; grep -c 'hl.workspace_rule(' "$f"
grep -nE '\$mainMod|\$sky|\$teal|bindm|bindel|exec-once|monitorv2|windowrule|layerrule' "$f"
```
Expected for the last command: no output.

- [ ] **Step 3: Syntax-check the Lua**

```bash
nix shell nixpkgs#lua5_4 -c luac -p <path from step 1> \
  home/program-configs/linux/hypr/binds.lua \
  home/program-configs/linux/hypr/animations.lua
```
Expected: no output (syntax OK). `hl` being undefined is fine — `luac -p` only parses.

- [ ] **Step 4: No commit**

This task changes no files.

---

### Task 4: Switch and verify the live session

**Files:**
- Test: live session on the desktop host

**Interfaces:**
- Consumes: the verified build from Task 3.
- Produces: a running Lua-configured session, or a rollback decision.

- [ ] **Step 1: Note the rollback path before switching**

Rollback is a one-line change: set `configType = "hyprlang"` in `home/program-configs/linux/hyprland.nix` and `git revert` the migration commits, or boot the previous generation from the bootloader. Hyprland also has an emergency mode — if the Lua config errors out so badly that no binds register, `SUPER + Q` stays alive (binary string: `Emergency mode tripped: A lua config error resulted in no binds being registered. Emergency binds active: SUPER + Q`). Know this before you log out.

- [ ] **Step 2: Switch**

```bash
cd /home/paul/git/nixos && sudo nixos-rebuild switch --flake .#desktop
```
Expected: succeeds. HM removes `~/.config/hypr/hyprland.conf` and creates `hyprland.lua`, `binds.lua`, `animations.lua`, `autostart.lua`, `.luarc.json`.

```bash
ls -la ~/.config/hypr/
```
Expected: `hyprland.conf` is gone; `hyprland.lua` present.

- [ ] **Step 3: Log out and back in**

A full re-login, not `hyprctl reload` — the point is to exercise the uwsm startup path. After login:

```bash
hyprctl version | head -1
journalctl --user -b -u 'wayland-wm@hyprland.service' --no-pager | tail -30
```
Expected: no `Lua config error`, no `Emergency mode tripped`, service active.

- [ ] **Step 4: Walk the verification checklist**

- [ ] Deprecation warning is **gone** (no `.conf config format` notification on startup).
- [ ] All three monitors come up at their configured modes: `hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate)"'`
- [ ] Workspace pins hold: workspace 1 on HDMI-A-1, 2 on DP-3, 3 on DP-2.
- [ ] Autostart: quickshell bar visible, Discord on ws 2, Spotify on ws 2, wallpaper set, Telegram/Steam/seadrive in tray.
- [ ] Spotify went through PulseAudio, not ALSA (`pactl list sink-inputs | grep -i spotify`).
- [ ] `SUPER+RETURN` opens kitty, `SUPER+SHIFT+RETURN` opens rofi, `SUPER+E` opens thunar.
- [ ] `SUPER+SHIFT+Q` closes a window; `SUPER+F` toggles fullscreen; `SUPER+V` toggles floating.
- [ ] `SUPER+1..0` switches workspaces; `SUPER+SHIFT+1..0` moves windows. **Check workspace 10 specifically** — the `i % 10` loop maps key `0` to workspace 10.
- [ ] `SUPER+S` toggles the special workspace; `SUPER+CTRL+S` moves a window there.
- [ ] `SUPER+drag` (LMB) moves and `SUPER+drag` (RMB) resizes.
- [ ] Volume/brightness/media keys work, including while locked.
- [ ] `SUPER+TAB` toggles dwindle ↔ scrolling: `hyprctl getoption general:layout` before and after must differ. Then `SUPER+period`/`comma`/`R`/`G`/`M`/`C`/`X`/`U` in scrolling mode.
- [ ] Window rules: open Thunar and start a long copy (float, 600x300, centred); open Steam Big Picture (fullscreen on HDMI-A-1); open the Bitwarden extension popup (floating).
- [ ] Quickshell layer is blurred (the `quickshell-blur` layer rule).
- [ ] Animations run — borders and glow angle animate (`borderangle`/`glowangle` with `style = "loop"`).
- [ ] `SUPER+L` locks via hyprlock and unlocks. (hyprlock keeps its own hyprlang config; unaffected.)
- [ ] `SUPER+SHIFT+S` screenshots via grimblast.
- [ ] `SUPER+SHIFT+E` shuts down cleanly.

Record any item that fails; each becomes a fix before Task 5.

- [ ] **Step 5: Fix and re-verify, then commit any fixes**

If items failed, fix them in `binds.lua` / `animations.lua` / `hyprland.nix`, rebuild, switch, and re-check only the failed items. Commit fixes individually:
```bash
cd /home/paul/git/nixos
git add -A && git commit -m "hyprland: fix <specific item> under the Lua config"
```

---

### Task 5: Laptop host

**Files:**
- Test: live session on the laptop host

**Interfaces:**
- Consumes: the verified desktop session from Task 4 and the laptop monitors module from Task 2.
- Produces: a verified laptop session.

- [ ] **Step 1: Switch on the laptop**

```bash
cd /home/paul/git/nixos && sudo nixos-rebuild switch --flake .#laptop
```

- [ ] **Step 2: Log out, log back in, and verify the laptop-specific parts**

- [ ] eDP-1 comes up at 1920x1200@60 with the HDR/colour-management values.
- [ ] Touchpad: `natural_scroll` and `scroll_factor = 0.2` behave as before.
- [ ] Three-finger horizontal gesture switches workspaces (`hl.gesture`).
- [ ] Brightness keys work (`XF86MonBrightnessUp`/`Down` with `locked = true, repeating = true`).
- [ ] No deprecation warning.

Note: the desktop-only autostart entries (Steam, StreamController, gsr-ui) are in the shared module and will also try to start on the laptop — same as before this migration. Not a regression; do not "fix" it here.

- [ ] **Step 3: Commit any laptop-specific fixes**

```bash
cd /home/paul/git/nixos
git add -A && git commit -m "hyprland: fix <specific item> on the laptop under the Lua config"
```

---

### Task 6: Theme switcher — `hyprctl keyword` → `hyprctl eval`

This is the one thing the migration actively breaks. `hyprctl keyword` returns `keyword can't work with non-legacy parsers. Use eval.` under the Lua config manager, and the zen/mocha/liquidglass switch is built entirely on it. Do this task even if Task 4's checklist passed — the breakage is silent (the Process just gets an error string back).

**Files:**
- Modify: `/home/paul/git/dotfiles/.config/quickshell/Theme.qml:140-167`
- Modify: `/home/paul/git/nixos/flake.lock` (via `nix flake update dotfiles`)
- Test: live theme switching in the session

**Interfaces:**
- Consumes: the colour literals from `hyprland.nix` (`sky = "rgb(89dceb)"`, `teal = "rgb(94e2d5)"`) and the zen/mocha defaults documented at `hyprland.nix` `general.gaps_out` / `decoration.glow`.
- Produces: a Theme.qml that drives Hyprland through `hyprctl eval`.

- [ ] **Step 1: Confirm the breakage first**

In the running Lua-configured session:
```bash
hyprctl keyword decoration:rounding 10
```
Expected output: `keyword can't work with non-legacy parsers. Use eval.`

Then confirm the replacement works:
```bash
hyprctl eval "hl.config({ decoration = { rounding = 20 } })"
hyprctl getoption decoration:rounding
```
Expected: `ok`, then `int: 20`. Restore with `hyprctl eval "hl.config({ decoration = { rounding = 12 } })"`.

- [ ] **Step 2: Rewrite the payloads in Theme.qml**

In `/home/paul/git/dotfiles/.config/quickshell/Theme.qml`, replace lines 140-151 (the `hyprZen` / `hyprRestore` properties). Lua single-quoted strings are used for the colours so the QML double-quoted string needs no escaping:

```qml
    // Restore = Alt-Werte für mocha/liquidglass. Läuft auch beim Start →
    // selbstheilend.
    // Hyprland 0.57 entfernt das .conf-Format; unter dem Lua-Config-Manager
    // antwortet `hyprctl keyword` mit "keyword can't work with non-legacy
    // parsers. Use eval." → wir schicken stattdessen einen hl.config()-Aufruf
    // durch `hyprctl eval`. Ein einziger Aufruf statt --batch, weil hl.config
    // ohnehin ein verschachteltes Table nimmt.
    readonly property string hyprZen:
        "hl.config({ " +
        "general = { gaps_out = { top = 12, right = 22, bottom = 22, left = 22 }, " +
        "col = { active_border = 'rgb(94e2d5)' } }, " +
        "decoration = { rounding = 12, glow = { enabled = false } } })"
    readonly property string hyprRestore:
        "hl.config({ " +
        "general = { gaps_out = 10, " +
        "col = { active_border = { colors = { 'rgb(89dceb)', 'rgb(94e2d5)' }, angle = 45 } } }, " +
        "decoration = { rounding = 10, glow = { enabled = true } } })"
```

Then replace line 165 (inside `applyHyprland()`):

```qml
        hyprProc.command = ["hyprctl", "eval", variant === "zen" ? hyprZen : hyprRestore]
```

The surrounding `hyprProc.running = false` / `= true` dance stays exactly as it is — the double-toggle reasoning in the existing comment is unaffected.

- [ ] **Step 3: Test against the live session before committing**

Quickshell reads its config from `~/.config/quickshell`, which is a symlink into the store — so test the payloads directly first:

```bash
hyprctl eval "hl.config({ general = { gaps_out = { top = 12, right = 22, bottom = 22, left = 22 }, col = { active_border = 'rgb(94e2d5)' } }, decoration = { rounding = 12, glow = { enabled = false } } })"
hyprctl getoption general:gaps_out
hyprctl getoption decoration:rounding
hyprctl getoption general:col.active_border
```
Expected: `ok`; `css gap data: 12 22 22 22`; `int: 12`; a single-colour gradient.

```bash
hyprctl eval "hl.config({ general = { gaps_out = 10, col = { active_border = { colors = { 'rgb(89dceb)', 'rgb(94e2d5)' }, angle = 45 } } }, decoration = { rounding = 10, glow = { enabled = true } } })"
hyprctl getoption general:gaps_out
hyprctl getoption decoration:rounding
hyprctl getoption general:col.active_border
```
Expected: `ok`; `css gap data: 10 10 10 10`; `int: 10`; a two-colour gradient at 45deg.

If a payload errors, fix it here before touching Theme.qml further.

- [ ] **Step 4: Commit and push the dotfiles change**

```bash
cd /home/paul/git/dotfiles
git add .config/quickshell/Theme.qml
git commit -m "quickshell: drive Hyprland theme switch via hyprctl eval

hyprctl keyword only works with the legacy .conf parser. The NixOS config
moved to Hyprland's Lua format, so the zen/mocha/liquidglass switch now
sends a single hl.config() call through hyprctl eval instead."
git push
```

- [ ] **Step 5: Bump the flake input and switch**

```bash
cd /home/paul/git/nixos
nix flake update dotfiles
sudo nixos-rebuild switch --flake .#desktop
```

- [ ] **Step 6: Verify the full theme cycle**

Run `~/.config/quickshell/scripts/theme-switch.sh` through a complete cycle (or `SUPER+SHIFT+T` → menu) and check after each variant:

- [ ] **zen**: `hyprctl getoption general:gaps_out` → `12 22 22 22`; `decoration:rounding` → `12`; `general:col.active_border` → single colour; glow off.
- [ ] **mocha**: gaps_out `10`, rounding `10`, two-colour gradient at 45deg, glow on.
- [ ] **liquidglass**: same Hyprland values as mocha.
- [ ] Fast double-toggle still lands on the correct final state (the `running = false` reset).
- [ ] Restart quickshell (`pkill -f quickshell; uwsm app -- quickshell`) and confirm it self-heals to the correct Hyprland values on startup.

- [ ] **Step 7: Commit the lock bump**

```bash
cd /home/paul/git/nixos
git add flake.lock
git commit -m "flake: bump dotfiles for the hyprctl eval theme switch"
```

---

### Task 7: Clean up and document

**Files:**
- Modify: `/home/paul/git/dotfiles/.config/hypr/hyprland.conf` (delete)
- Create: `docs/superpowers/specs/2026-08-07-hyprland-lua-config-design.md`

**Interfaces:**
- Consumes: everything verified in Tasks 4-6.
- Produces: a design note matching the repo's existing `docs/superpowers/specs/` convention.

- [ ] **Step 1: Remove the stale dotfiles hyprland.conf**

`/home/paul/git/dotfiles/.config/hypr/hyprland.conf` is a leftover from before Home Manager took over the Hyprland config — nothing symlinks to it (`~/.config/hypr/hyprland.conf` pointed into the HM files derivation). Confirm, then delete:

```bash
cd /home/paul/git/dotfiles
grep -rn "hypr/hyprland.conf" /home/paul/git/nixos --include="*.nix"
```
Expected: no output (nothing references it).

```bash
git rm .config/hypr/hyprland.conf
git commit -m "hypr: drop the stale pre-Home-Manager hyprland.conf

Nothing has symlinked this since Home Manager took over the Hyprland
config, and the .conf format is removed in Hyprland 0.57 anyway."
git push
```

- [ ] **Step 2: Write the design note**

Create `docs/superpowers/specs/2026-08-07-hyprland-lua-config-design.md` covering, in English:
- Why: the 0.57 deprecation, with the verbatim warning string.
- The hybrid split and why binds/curves/autostart are raw Lua while the rest is Nix attrsets.
- The `extraLuaFiles`-before-`settings` ordering constraint, and that `animations.enabled` lives in `animations.lua` because of it.
- The `hyprctl keyword` → `hyprctl eval` breakage, with the source reference (`src/debug/HyprCtl.cpp:1162`), because that is the non-obvious cross-repo coupling.
- That `hyprctl getoption` still works in both modes.
- Where the reference material lives: `$hyprland/share/hypr/hyprland.lua` and `share/hypr/stubs/hl.meta.lua`.
- Rollback: flip `configType` back to `"hyprlang"`; Hyprland prefers `hyprland.lua` only when it exists.

- [ ] **Step 3: Commit**

```bash
cd /home/paul/git/nixos
git add docs/superpowers/specs/2026-08-07-hyprland-lua-config-design.md
git commit -m "docs: add the Hyprland Lua config migration design note"
```

---

## Open questions to resolve during execution

These are places where the plan makes a specific choice that should be confirmed against the live session rather than assumed:

1. **`fullscreen = true` in the `steam-bigpicture` window rule.** The old rule used `fullscreen = 1`. Window rule values pass through generically to the same rule engine, so `true` should be equivalent — but Steam Big Picture is the one rule where a wrong value is visible immediately. Verify in Task 4; if it misbehaves, try `fullscreen_state` per `HL.WindowRuleSpec`.
2. **`hl.get_config("general.layout")` return type.** The `SUPER+TAB` toggle compares it to the string `"scrolling"`. `general.layout` is a string option (`HL.ConfigOpt.General.layout? string`), and `get_config` returns `any, string?`. If the comparison never matches, print the value with `hyprctl eval "hl.notification.create({ text = tostring(hl.get_config('general.layout')), timeout = 3000 })"` and adjust.
3. **`use_shader_blur_blend`.** It is commented out today with the value `1`; the stub types it as `boolean`. Left commented out — if it is ever re-enabled, it must be `true`, not `1`.
