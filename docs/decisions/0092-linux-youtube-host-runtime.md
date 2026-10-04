# ADR-0092: Linux YouTube v1 ships with host-provided WPE runtime

**Status**: Accepted (2026-10-02)
**Amends**: [ADR-0091](0091-youtube-linux-playback.md) — narrows FR-008's
self-containment for the YouTube playback runtime only (v1).
**Feature spec**: [specs/047-youtube-linux-playback](../../specs/047-youtube-linux-playback/spec.md)

## Context

S1 implementation evidence (specs/047 quickstart, "Spike evidence" + "T046
verdict") established three facts on real hardware:

1. WebKit spawns WebProcess/NetworkProcess from a **compile-time absolute
   path** (`/usr/lib/wpe-webkit-2.0/…`) with **no environment override**. A
   bundled WPE UI library therefore always launches the **host's** helper
   binaries — a bundled 2.52 UI library paired with a host 2.48 helper aborts
   (verified: missing-ICU loader failure, then IPC abort).
2. Hardware frame export stalls on WPEPlatform on the tested stack (amdgpu +
   Hyprland/Wayland) for **both** 2.48.7 and 2.52.6; software GL
   (`LIBGL_ALWAYS_SOFTWARE=1`) renders and exports frames correctly through the
   same path. There is no known-good bundled WPE version.
3. The dependency closure must exclude the host GL/Mesa family (bundled Mesa
   cannot find its DRI drivers) — GL is already host-provided by the same
   reasoning.

## Decision

Linux v1 resolves the **webview runtime (WPE WebKit + GStreamer) from the
host**, while everything else in the image stays self-contained:

- The packaging step removes the WPE library family that the plugin's bundling
  drops into `bundle/lib`; the plugin resolves WPE from the host exactly as it
  resolves GL.
- The **GStreamer plugin set stays bundled** (shadowing the host via
  `GST_PLUGIN_SYSTEM_PATH`) — plugins are dlopened, version-mixing with the
  host is avoided, and the decoder set is a verified unit.
- The runtime availability probe (ADR-0091, FR-004) already turns a missing or
  broken host runtime into the graceful localized unavailable state; the
  feature docs carry the exact host package list
  (`wpewebkit` + `gst-plugins-good/bad/libav`).
- The frame-watchdog software-GL fallback (specs/047 T047) remains planned for
  hosts where hardware export stalls.

## Alternatives

- **Self-built patched WebKit** (runtime-relative WebProcess resolution baked
  into a vendored wpewebkit build): true zero-install, but adds a WebKit build
  and patch-maintenance surface to CI. Deferred; ADR-0092 is amenable to
  supersession once that pipeline exists.
- **bubblewrap bind-mount trick** (bind the image's WPE dir over the host's
  compiled-in path in AppRun): no WebKit patch, but depends on unprivileged
  user namespaces (disabled on hardened/enterprise kernels) and adds a launch
  wrapper failure mode. Revisit if host-install friction proves real.

## Upstream issues

Filed with the S1 reproduction evidence: [initialUrlRequest is ignored on
Linux](https://github.com/pichillilorenzo/flutter_inappwebview/issues/2903)
(why the probe and the player navigate via `loadUrl`) and [teardown race
crashing the process with a glibc robust-mutex
assertion](https://github.com/pichillilorenzo/flutter_inappwebview/issues/2904)
(watched under the 24h soak, specs/047 T042).

## Consequences

- Ubuntu users need one apt line for YouTube playback; the app tells them
  precisely what is missing (FR-005) instead of failing silently. This is a
  deliberate FR-008 exception scoped to the webview runtime — local media
  playback remains fully self-contained.
- Version alignment between the image's WPE and the host's helper binaries is
  no longer our problem to solve per-release (host is self-consistent by
  definition of the distro packages).
- The known hardware-export stall keeps `LIBGL_ALWAYS_SOFTWARE` in the
  dev/troubleshooting toolbox and T047 as the shipping mitigation.
