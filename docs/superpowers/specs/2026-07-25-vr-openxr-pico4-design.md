# VR/OpenXR on paul-desktop (Pico 4 + WiVRn + xrizer)

Date: 2026-07-25 · Status: Implemented (status updated 2026-08-03)

## Goal

Play SteamVR games (Proton) on the desktop (NVIDIA, Hyprland/Wayland) in VR,
streamed to a Pico 4 over WLAN (PC on Ethernet, headset on 5 GHz WLAN).
Fully declarative, without SteamVR: WiVRn is the OpenXR runtime and the
streaming server, xrizer translates the OpenVR API of SteamVR games to OpenXR.

```
Pico 4 (WiVRn client app)
   │  5 GHz WLAN ←→ Router ←→ Ethernet
   ▼
WiVRn server (systemd user service, OpenXR runtime, Monado-based)
   ▲                    ▲
   │ OpenXR             │ OpenXR
native OpenXR apps    xrizer (OpenVR → OpenXR)
                        ▲
                        │ OpenVR API
                      SteamVR games under Proton
```

Packages used from the pinned nixpkgs: `wivrn` 26.6.2 (with NixOS module
`services.wivrn` incl. Steam integration), `xrizer` 0.5.

## Design

### 1. WiVRn server (`hosts/desktop/vr.nix`, new)

Desktop host only, imported in `hosts/desktop/default.nix` — analogous to
`gaming.nix` & co.

- `services.wivrn`:
  - `enable`, `openFirewall` (port 9757 TCP/UDP), `autoStart` (server starts
    with the user session), `highPriority` (CAP_SYS_NICE for compositing).
  - `steam.importOXRRuntimes`: exports
    `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1` so that Proton games inside
    the Steam sandbox can reach the runtime (`steam.enable` is on by default).
  - `config` stays empty: the stock package can do Vulkan video encode
    (hardware encoding on NVIDIA without a CUDA build); encoder/bitrate are
    set at runtime in the WiVRn dashboard. NVENC would require an
    unfree, uncached CUDA build — YAGNI.
  - `monadoEnvironment`: empty; only set it for concrete NVIDIA problems.
- Avahi/mDNS for auto-discovery is enabled by the module itself.
- Tools as `environment.systemPackages`: `wayvr` (desktop overlay in VR,
  successor of wlx-overlay-s), `android-tools` (adb for the one-time
  client installation; USB access comes via systemd uaccess rules).

### 2. xrizer as the OpenVR "driver" (no dedicated config needed)

The nixpkgs WiVRn package bundles xrizer as the default entry in
`OVR_COMPAT_SEARCH_PATH`; the WiVRn server manages
`~/.config/openvr/openvrpaths.vrpath` and the active OpenXR runtime itself
(which is why the earlier module option `defaultRuntime` was removed). No
home-manager configuration is needed — SteamVR games automatically end up
at xrizer as soon as the WiVRn server is running.

### 3. Game launch (documentation, no config)

- Thanks to `services.wivrn.steam.enable` no launch option is needed; if a
  game still does not see the socket, the documented fallback is:
  `PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%`
- Native OpenXR games need nothing further (the runtime is set system-wide).
- Audio + microphone run via PipeWire; on connect, WiVRn creates its own
  sink/source pair and routes automatically.

### 4. Headset side (one-time, manual — the only non-declarative part)

1. Pico 4: enable developer mode (Settings → General → About,
   tap the version number several times, then Developer options → USB debugging).
2. Download the WiVRn client APK from the WiVRn GitHub release matching the server version.
3. Connect the headset to the PC via USB, `adb install wivrn-client…apk`, confirm
   the debugging prompt in the headset.
4. Start the app on the Pico — the PC shows up automatically via mDNS; confirm
   the connection once in the WiVRn dashboard on the PC.

Important: client and server versions must match; after a
nixpkgs update with a new WiVRn version, update the client APK if needed.

## Verification

1. `nix build` of the desktop configuration does not fail; after rebuild,
   `wivrn.service` (user) is running and listening on 9757.
2. The Pico 4 finds the PC automatically and connects; the WiVRn dashboard shows
   the stream, the headset shows the Monado void scene.
3. A SteamVR game from the library launches via Proton, renders in the headset,
   controllers and audio (PipeWire) work.

## Troubleshooting findings (2026-07-25)

- **GE-Proton11-1 is broken for VR titles:** DXVK fails with
  `VK_ERROR_EXTENSION_NOT_PRESENT` during device creation (Unity reports
  "InitializeEngineGraphics failed"). Cause chain: on the legacy query
  `xrGetVulkanDeviceExtensionsKHR`, WiVRn/Monado reports Linux-only extensions
  (`VK_KHR_external_memory_fd`), xrizer passes them through untranslated, and
  GE-Proton11-1 (wine-staging 11.0) does not translate them into the
  `_win32` counterparts — winevulkan rejects. **Fix: pin VR games in Steam to
  "Proton Experimental"** (Properties → Compatibility). Flat
  games are not affected. Re-test on future GE-Proton updates.
- Diagnosis path if it happens again: `PROTON_LOG=1 %command%`, then search
  `~/steam-<appid>.log` for `VK_ERROR_EXTENSION_NOT_PRESENT`;
  the xrizer log is at `~/.local/state/xrizer/xrizer.txt`.

## Out of scope

ALVR/SteamVR fallback, lighthouse/full-body tracking, sim-racing specifics,
the laptop host. All of it can be retrofitted later; for games that do not
run with xrizer, ALVR + SteamVR is the documented plan B.
