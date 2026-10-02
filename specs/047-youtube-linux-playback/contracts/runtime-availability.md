# Contract: Runtime YouTube Availability (Dart interface)

**Consumers**: all six YouTube gate call sites (open coordinator, engine-swap
coordinator, `warmYoutubeSurface`, player engine mount/open, video stage,
sign-in screen).
**Owner**: `lib/core/platform/linux_platform_availability.dart` (the decision's
single home — file keeps its name and location).

## Interface

```dart
/// Resolved once per process on first consultation; cached afterwards.
/// Non-Linux platforms short-circuit to available (no behavior change).
Future<YouTubeAvailability> resolveYouTubeAvailability(Ref ref);

sealed class YouTubeAvailability {
  const YouTubeAvailability();
  bool get canPlay;
}

class YouTubeAvailable extends YouTubeAvailability { const YouTubeAvailable(); ... }

class YouTubeUnavailable extends YouTubeAvailability {
  final YouTubeUnavailableReason reason;   // UnsupportedPlatform | RuntimeMissing |
  const YouTubeUnavailable(this.reason);   //   RuntimeInitFailed | DisabledByBuild
}
```

Exposed to widgets via a Riverpod provider that resolves lazily and caches for
the process lifetime (data-model Entity 1). The build-time kill-switch constant
stays in the same file and is ANDed into every result.

## Behavioral contract (must hold for every consumer)

| # | Rule |
|---|------|
| A1 | On non-Linux platforms `canPlay` is always `true`; no probe ever runs. |
| A2 | `resolveYouTubeAvailability` resolves at most once per process; concurrent callers share one probe. |
| A3 | A probe failure yields `unavailable{RuntimeInitFailed}` or `unavailable{RuntimeMissing}` — it never throws to a call site. |
| A4 | With the kill switch on, every result is `unavailable{DisabledByBuild}` regardless of probe outcome. |
| A5 | Gate call sites treat `unavailable` uniformly: user-initiated opens surface the localized message + browser action (FR-005); warm-ups no-op silently (FR-005 scenario 3). |
| A6 | Probe duration is bounded (≤ 5 s, see data-model Entity 2); the bound itself maps to `RuntimeInitFailed`. |
| A7 | Probe failures and reasons are logged via the standard diagnostic logging facility — never `print` (FR-013, constitution logging rule). |

## UI contract

| # | Rule |
|---|------|
| U1 | The unavailable state text and the "open in browser" action label exist in ARB files for every supported locale (FR-012). |
| U2 | The browser action opens the video's canonical watch URL via the existing URL-launcher pathway; if the launch itself fails, only the launch error surfaces — playback state stays coherent. |
| U3 | The unavailable state is reachable in widget tests by overriding the availability provider (test seam), which is how SC-006 is verified scenario-by-scenario. |

## Invariants inherited from the existing engine (must not drift)

- The poll loop cadence and JS bridge call set in
  `youtube_webview_bridge.dart` stay identical on Linux and the other desktop
  platforms — no Linux-only bridge dialect (spec US3 parity).
- In-player navigation to Google sign-in stays cancelled on Linux (FR-006,
  ADR-0025).
- Transcript fetching keeps using the platform-independent pipeline; Linux
  gains no transcript-specific code path (FR-003).
