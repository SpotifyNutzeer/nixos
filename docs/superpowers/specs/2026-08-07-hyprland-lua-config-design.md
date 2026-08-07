# Hyprland config migrates from hyprlang to Lua

Date: 2026-08-07

## Goal

Move the Hyprland configuration off the deprecated hyprlang `.conf` format and
onto Hyprland's Lua format, before 0.57 removes `.conf` support entirely. The
running 0.56.1 binary warns:

```
You are using the .conf config format, support for which will be removed in Hyprland 0.57.
```

0.56 accepts both formats, which is what made this migration testable and
reversible. Under 0.57 the choice is gone.

## Non-goals

- No Hyprland version bump. The migration was done on 0.56.1 precisely so both
  formats work while switching.
- No behaviour changes. Every setting was carried over as-is; the goal was a
  faithful translation, not a redesign.
- No hyprlock migration. Hyprlock is a separate project with its own hyprlang
  parser and is unaffected by this deprecation. `hyprlock.conf` stays as it is.

## Where the config lives now

Home Manager already supports this: `configType` is an enum of
`[ "hyprlang" "lua" ]`, and the default for stateVersion >= 26.05 is already
`"lua"`. The module had been explicitly pinned to `"hyprlang"`.

The split is hybrid, by how well each block survives the Nix -> Lua rendering:

| Where | What | Why |
|---|---|---|
| `hyprland.nix` `settings` | `hl.config`, `window_rule`, `layer_rule`, `gesture`, `device` | Attrsets map 1:1; HM renders `settings.<name>` as `hl.<name>(...)` and a list as one call per element |
| `hosts/*/hyprland-monitors.nix` | `hl.monitor`, `hl.workspace_rule` | Per-host, stays diffable; only the key names changed (`monitorv2` -> `monitor`) |
| `hypr/binds.lua` | all keybinds | 53 binds read far better as real Lua than through `_args` + `mkLuaInline` escaping |
| `hypr/animations.lua` | curves + animations | Same reason |
| `hyprland.nix` `extraLuaFiles.autostart` | the `hyprland.start` hook | Inline Nix string because it needs `${dotfiles}` interpolated |

### Ordering constraint

HM's generated file is assembled in this order (`lib.nix`, `luaConfig`):

```
plugins -> extraLuaFiles requires -> settings -> submaps -> start hook -> shutdown hook -> extraConfig
```

`extraLuaFiles` are required **before** the `hl.config(...)` calls generated from
`settings`. That is why `animations.enabled` is set inside `animations.lua`
rather than in `settings` — the file must not depend on `settings` having run.

## The cross-repo coupling: `hyprctl keyword` is dead under Lua

This is the non-obvious part, and the reason the migration touched two repos.

`src/debug/HyprCtl.cpp`, `dispatchKeyword`:

```cpp
if (Config::mgr()->type() != Config::CONFIG_LEGACY)
    return "keyword can't work with non-legacy parsers. Use eval.";
```

The Quickshell theme switcher (`dotfiles/.config/quickshell/Theme.qml`) drove the
zen/mocha/liquidglass coupling with `hyprctl --batch keyword ...`. It now sends a
single `hl.config()` call through `hyprctl eval` instead.

The failure mode was worse than "theme switching stops working". `applyHyprland()`
runs at Quickshell **startup**, not only on a manual switch — the code calls this
self-healing. Under the Lua manager that startup call failed silently, so the
decoration would never be reconciled with the persisted variant. Since the
committed defaults in `hyprland.nix` are the zen variant, a mocha/liquidglass
user would have come up with zen decoration and a mocha palette.

Two related commands are **not** affected and still work in both modes:

- `hyprctl getoption` — goes through `Config::mgr()->getConfigValue()`, not the
  legacy parser.
- `hyprctl reload` — `reloadRequest` has no parser-type check at all.

Conversely `hyprctl eval` is Lua-only (`evalRequest` rejects `CONFIG_LEGACY`).

`hyprctl dispatch` works in both, but changes meaning: under Lua it wraps the
argument as `return hl.dispatch(<in>)`. So `hyprctl dispatch 'hl.dsp.exit()'` is
correct and `hyprctl dispatch exit` is not — the latter evaluates `hl.dispatch(exit)`
with `exit` an undefined global. Hyprland has a dedicated branch that detects this
and appends "your syntax might need to be updated".

The SUPER+TAB dwindle/scrolling toggle used to shell out to `hyprctl keyword`. It
is now a native `hl.get_config` / `hl.config` pair inside a Lua callback, which is
both faster and immune to this whole class of problem.

## Reference material

Do not reconstruct the Lua API from memory. The Hyprland package ships both:

- `$hyprland/share/hypr/hyprland.lua` — upstream's default config in Lua. It is
  recognisably the same template this config descends from (same bezier curves,
  same `fix-xwayland-drags` rule, even the same `move-hyprland-run` rule), which
  made it the primary translation reference.
- `$hyprland/share/hypr/stubs/hl.meta.lua` — 1770 lines of LSP stubs: every
  `hl.*` function, every valid `hl.config` key, every event name.

Note that `HL.WindowRuleSpec` in the stubs only types `enabled`, `match` and
`name`. The rule-property fields (`suppress_event`, `no_focus`, `float`, `move`,
`workspace`, `monitor`, `fullscreen`, `center`, `size`) are not enumerated there,
but they are valid: `hlWindowRule` special-cases only those three and passes
everything else to the same rule engine that hyprlang v3 rules use. That is a gap
in the stub's typing, not a constraint on the config.

`.luarc.json` is **not** generated here. HM gates it on `finalPackage != null`
and this config sets `package = null` (the compositor comes from the system-level
`programs.hyprland`). Its absence is expected.

## Rollback

Set `configType = "hyprlang"` and rebuild. Hyprland prefers `~/.config/hypr/hyprland.lua`
and only falls back to `hyprland.conf` when the Lua file is absent:

```
[cfg] Using lua config found at {}
[cfg] Lua config not found, using legacy config at {}
```

So whichever file Home Manager writes wins, with no further cleanup needed.

If a Lua error is bad enough that no binds register at all, Hyprland trips an
emergency mode and keeps `SUPER + Q` alive.

One transition artefact to be aware of: when Home Manager removed the old
`hyprland.conf` symlink during the rebuild, the still-running hyprlang session
reloaded, found no config, and wrote itself a default stub at that path. It was
inert (the Lua file takes precedence) but would have become a silent fallback if
`hyprland.lua` ever went missing. Deleted after the switch.

## Verified on the live session

Beyond the build: monitors at configured modes, workspace pins, all autostart
entries, Spotify reaching PipeWire via `api=pipewire-pulse` with its `pulse.rules`
target intact, every keybind by hand, mouse drag/resize, the scrolling layout
toggle, hyprlock, and the full zen/mocha/liquidglass cycle including the
self-heal-on-restart path.

One pre-existing bug surfaced during the walkthrough and was fixed here: the
`XF86AudioNext/Pause/Play/Prev` binds call `playerctl`, which was declared nowhere
in the config and had never been installed. The binds had always fired into a
missing binary. `brightnessctl` is deliberately left alone — it ships only on the
laptop host, so the two brightness binds in the shared `binds.lua` are inert on
the desktop, which is correct there.
