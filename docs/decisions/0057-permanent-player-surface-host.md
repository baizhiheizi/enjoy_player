# ADR-0057: Permanent RootShell player surface host

## Status

Accepted

## Context

Vocabulary review Play clip and the expanded player both need a native video
surface (media_kit `Video` or YouTube `InAppWebView` / WebView2). Hosting that
surface inside modal trees, `Visibility`/`Offstage`, or reparenting a keyed
WebView between shell park and expanded player caused:

- MediaKit `VideoController` / `ValueNotifier` use-after-dispose when engines
  swapped while a clip widget still listened.
- Windows WebView2 hard crashes / blank review after modal dismiss.
- Fragile park-then-reparent ownership (`YoutubeSurfacePark`).

Open in player also raced with `pop()` + `mounted` checks and left only the
mini-bar.

## Decision

1. Mount one permanent `PlayerSurfaceHost` in `RootShell`. It is the sole owner
   of `buildVideoStage()` for the active engine and is keyed by engine identity
   so swaps dispose the old surface before mounting the new one.
2. Viewports (review clip, expanded player, loading stage) register
   `PlayerSurfaceTarget` geometry via `playerSurfaceRegistryProvider`. The host
   updates one permanent `Positioned` stage using global target bounds; when no
   target is attached, it parks off-corner. Avoiding follower transforms keeps
   WebView2 bounds correct under Windows display scaling.
3. Vocabulary clip practice uses an explicit phase
   (`clipOpening` then `clipReady`) and only claims the portal after media open /
   engine resolution completes. Dismiss pauses, deactivates the clip window,
   clears the playback session (no mini-bar), and parks the surface without
   clearing the review queue.
4. Open in player/source is a single `context.replace` with a typed
   `PlayerLaunchRequest` (query-encoded). The launch pipeline owns
   deactivate, explicit open, readiness, seek, activation of the context echo
   window, then autoplay in the normal expanded player/transcript screen.
5. Review Echo is recorder-only (`ShadowReadingPanel` with context metadata);
   it does not open media or activate global echo mode.

## Consequences

- Modal show/hide cannot tear down WebView2.
- Chrome overlays live in the host layer (or outside the target) so controls
  stay above the native surface.
- Feature code must not call `buildVideoStage()` / build `InAppWebView` outside
  the host.
- Supplements ADR-0015 (YouTube WebView) and ADR-0003 (single player).

## Related

- [vocabulary.md](../features/vocabulary.md)
- [ADR-0015](0015-youtube-playback.md)
- [ADR-0003](0003-player-core-media-kit.md)
