# ADR-0098: Linux YouTube software-GL recovery persists across launches

**Status**: Accepted (2026-10-16)
**Amends**: [ADR-0092](0092-linux-youtube-host-runtime.md) — replaces the
in-session engine-rebuild form of the frame-watchdog fallback (specs/047
T047) with a persistent, pre-engine recovery.

## Context

ADR-0092 shipped the frame watchdog with an in-session recovery: on a stall
verdict the app sets `LIBGL_ALWAYS_SOFTWARE=1` in its own process and rebuilds
the WebView. A 2026-10-16 field report (AMD + Hyprland, wpewebkit from Arch,
debug build) proved that recovery ineffective, with the failure captured end
to end:

- The watchdog verdict fired; the rebuilt WebView reused the **same
  `WebKitWebContext`** (identical environment id in the plugin log on both
  mounts), so WebKit's UI-process-side GL/dmabuf resources stayed on the
  hardware path they were created with.
- `/proc/<WPEWebProcess>/environ` showed the fresh sandboxed renderer *did*
  inherit `LIBGL_ALWAYS_SOFTWARE=1` — a software producer paired with the
  hardware UI-side allocator/import pipeline still exported zero frames.
- The plugin's zero-copy EGL texture imports on Flutter's raster context,
  created at app startup, before any flag could be set.
- The rebuilt engine's watchdog fired again ~5 s later and the
  once-per-controller guard swallowed it before logging.

`LIBGL_ALWAYS_SOFTWARE` is consulted by Mesa only at GL context creation.
Every effective configuration arms it before any context exists — the manual
workaround (`LIBGL_ALWAYS_SOFTWARE=1` at launch) is the verified-good path
(ADR-0092). Setting it after the app is running cannot repair the pipeline,
whatever is rebuilt afterwards.

## Decision

1. **Verdict persists; relaunch recovers.** The stall verdict writes a marker
   file (`webview_software_gl`) into the application-support directory
   ([`webview_software_gl_marker.dart`](../../lib/core/platform/webview_software_gl_marker.dart)).
   The Linux runner checks the marker in `main()`, before engine init, and
   sets `LIBGL_ALWAYS_SOFTWARE=1` for the whole process tree — the same
   configuration as the manual workaround. A user-set value of the variable
   always wins.
2. **No in-session rebuild.** The verdict no longer tears down and reopens
   the engine: that path cannot clear the stall and only interrupted audio.
   The stalled session keeps playing audio; the user relaunches to restore
   video. The runner logs the armed state; repeat verdicts log once.
3. **Reset is manual and documented.** Deleting the marker returns the app to
   hardware probing — the escape hatch if a driver/compositor fix lands.
   Re-evaluating the default belongs to ADR-0091/0092's per-release posture.

## Alternatives considered

- **Self-relaunch (`exec` with the env var)**: restores video without a
  manual restart, but adds a self-exec path, session-restore risk, and a
  second failure surface to a debug-only-severity path. Revisit if field
  reports show the relaunch step is the main pain.
- **Probe-time arming** (detect during the availability probe, set the flag,
  recreate the web context in-process): still leaves Flutter's raster context
  and the shared-context GL resources on hardware; only partially verified
  combinations, which is exactly what failed here.
- **SHM pixel-buffer texture fallback**: exists in the plugin
  (`FLUTTER_INAPPWEBVIEW_LINUX_DISABLE_GL`) but is unverified with YouTube
  playback and couples us further to a beta plugin's heuristics.

## Consequences

- The first stalled session stays black (audio only) by design; every later
  launch renders the whole app on llvmpipe until the marker is deleted —
  the known-good configuration, at the documented software-rendering cost.
- The runner owns two hardcoded strings (`ai.enjoy.player.enjoy_player`,
  `webview_software_gl`) that must mirror
  [`webview_software_gl_marker.dart`](../../lib/core/platform/webview_software_gl_marker.dart)
  and the `APPLICATION_ID` in `linux/CMakeLists.txt`.
- `restartWithSoftwareGl` (clear + reopen) is gone; the watchdog verdict API
  is now `PlayerController.markSoftwareGlStallVerdict`.
