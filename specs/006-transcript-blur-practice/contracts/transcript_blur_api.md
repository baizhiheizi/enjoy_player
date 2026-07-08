# Contract: Transcript Blur Public API (in-app)

**Feature**: [spec.md](spec.md) · [research.md](research.md) ·
[data-model.md](data-model.md)
**Phase**: 1 (design)
**Audience**: Contributors wiring the transcript blur feature into
other widgets / tests.
**Date**: 2026-07-08

This file is the in-app **UI / API contract** for the transcript blur
feature. There is no network contract — the feature is fully local and
does not call any external service. Riverpod providers are the
interface.

The terminology mirrors [data-model.md](data-model.md).

---

## C-01 — Preference notifier

```dart
@Riverpod(keepAlive: true)
class TranscriptBlurPreferencesCtrl extends _$TranscriptBlurPreferencesCtrl {
  // Hydrated from `prefs.transcript_blur_practice_enabled` and
  // `prefs.transcript_blur_tap_reveal_seconds` on first build via
  // SettingsDao.getValue.
  @override
  TranscriptBlurPreferences build();

  /// Sets the global toggle. Persists synchronously to SettingsDao.
  /// Idempotent — calling with the current value is a no-op.
  Future<void> setEnabled(bool value);

  /// Sets the tap-reveal hold duration in seconds. Clamped to [1, 15].
  /// Persists synchronously. Does NOT cancel an in-flight hold.
  Future<void> setTapRevealSeconds(int seconds);
}

/// Read-only state stream.
@riverpod
TranscriptBlurPreferences transcriptBlurPreferences(Ref ref);
```

**Contract**:

- `setEnabled(true)` MUST persist before returning. If persistence
  throws, the in-memory state is rolled back and the exception
  re-thrown (callers are expected to show an error notice).
- `setTapRevealSeconds` MUST clamp to `[1, 15]` and treat anything
  outside the range as a no-op (logged at warning).
- The notifier is `keepAlive: true`; it is never disposed during the
  app's lifetime.

---

## C-02 — Tap-reveal hold notifier

```dart
/// Per-mediaId ephemeral hold. autoDispose — disposed when no widget
/// is reading it. Owns a single Timer that fires `null` on expiry.
@riverpod
class TapRevealHoldCtrl extends _$TapRevealHoldCtrl {
  @override
  TapRevealHold? build();

  /// Starts (or replaces) the hold for [cueId]. Cancels any previous
  /// hold and any pending Timer.
  ///
  /// [holdSeconds] is the duration; pass `0` to cancel immediately.
  void setHold({required String cueId, required int holdSeconds});

  /// Cancels the hold immediately (no Timer fire).
  void clear();
}

/// Reads the current hold (null when no cue is on hold).
@riverpod
TapRevealHold? tapRevealHold(Ref ref, String mediaId);
```

**Contract**:

- Calling `setHold` twice in a row replaces the first hold atomically;
  the second cue becomes the only held cue; the first cue's tile
  re-blurs on its next frame.
- `holdSeconds <= 0` is equivalent to `clear()`.
- The Timer is cancelled on provider disposal; no late callbacks fire
  into a disposed provider.
- The provider family is keyed by `mediaId` — two open transcript
  panels do NOT share hold state.

---

## C-03 — Per-cue reveal provider

```dart
/// Returns true if [cueId] should be rendered WITHOUT the blur filter
/// right now. Reads preference state, the tap-reveal hold for
/// [mediaId], and (via the tile's local State) the hover flag passed
/// to [_BlurText].
@riverpod
bool transcriptCueReveal(Ref ref, String mediaId, String cueId);
```

**Contract**:

- The provider does NOT receive hover state as a parameter — hover is
  owned by the tile widget. The tile reads its local `_hover` flag and
  the provider's bool, then ORs them together in `build`.
- The provider is `autoDispose` — entries vanish when no widget reads
  them.
- The provider MUST NOT read `transcriptPlaybackHighlightProvider` —
  the active cue has no privileged reveal state (see
  [research.md R-004](../research.md) and the 2026-07-08
  Clarifications in the spec).

---

## C-04 — `cueId` identity

```dart
/// Canonical cue id for blur-feature providers and tests.
/// Stable across re-renders and across rebuilds of the same
/// TranscriptLine. Format: `"{startMs}:{endMs}:{hash}"`, where
/// `hash` is a short deterministic hash of the (trimmed) cue text.
/// Returned by `TranscriptBlurSupport.cueIdFor(TranscriptLine line)`
/// (a small helper in `lib/features/transcript/domain/`).
String cueIdFor(TranscriptLine line);
```

**Contract**:

- `cueIdFor` MUST return the same string for two `TranscriptLine`s
  with the same `(startMs, endMs, trimmedText)` regardless of markup
  (`<i>`, `<font>`, etc.) — markup is stripped before hashing.
- `cueIdFor` MUST be total — never throws, never returns null/empty
  (returns a sentinel `"__invalid__:{startMs}:{endMs}"` for empty
  text).
- Widget tests can construct cue ids by hand using the same format;
  they do NOT need to call `cueIdFor` directly.

---

## C-05 — `_BlurText` widget

```dart
/// Internal widget (private — exported only for tests).
///
/// Wraps [child] in an `ImageFiltered(imageFilter: ImageFilter.blur(...))`
/// when [revealed] is false; passes [child] through unchanged when
/// true. Honors `MediaQuery.disableAnimationsOf` to skip the fade
/// transition.
class _BlurText extends StatelessWidget {
  const _BlurText({required this.revealed, required this.child});
  final bool revealed;
  final Widget child;
}
```

**Contract**:

- `_BlurText` does NOT wrap the child in any layout-affecting widget;
  the parent's intrinsic dimensions are unchanged whether or not the
  blur is applied.
- `_BlurText` does NOT affect semantics — it is invisible to
  `Semantics` widgets (no `Semantics` node is added or removed).
- The blur sigma is constant (`6.0` on both axes) in v1.
- When `revealed` flips, the transition is either **instant**
  (`MediaQuery.disableAnimationsOf` true) or a **120 ms opacity fade**
  on the reveal-side overlay (false).

---

## C-06 — Toolbar widget

```dart
/// Public widget placed at the top of TranscriptPanel.
///
/// Contains the "Blur practice" toggle (EnjoyTappableIcon), a tooltip,
/// a haptic, and (in the future) a settings link to the hold-duration
/// slider. Renders nothing when the toggle is disabled and there are
/// zero cues (the panel takes care of that case via a parent
/// condition).
class TranscriptBlurToolbar extends ConsumerWidget {
  const TranscriptBlurToolbar({
    required this.mediaId,
    required this.hasLines,
    super.key,
  });

  final String mediaId;
  final bool hasLines;
}
```

**Contract**:

- When `hasLines == false`, the toolbar MUST still render the toggle
  but mark it disabled with the tooltip `transcriptBlurEmptyTooltip`
  (new ARB key).
- When `hasLines == true` and `prefs.enabled == false`, tapping the
  toggle calls `setEnabled(true)` and fires `Haptics.selection`.
- The toolbar is a pure presentational widget — it owns NO state
  beyond the Riverpod watch.
- Keyboard focus + Enter/Space MUST activate the toggle (provided by
  `EnjoyTappableIcon`).

---

## C-07 — Localization (ARB) keys to add

The implementation MUST add the following keys to `lib/l10n/app_en.arb`
and `lib/l10n/app_zh_CN.arb` (and regenerate `app_localizations*.dart`):

| Key | English value (placeholder — final copy in implementation) |
|---|---|
| `transcriptBlurToggleTooltip` | "Blur practice (focus on listening)" |
| `transcriptBlurToggleOn` | "Listening-focus mode on" |
| `transcriptBlurToggleOff` | "Listening-focus mode off" |
| `transcriptBlurEmptyTooltip` | "No transcript lines to practice with" |
| `transcriptBlurSettingsHoldDuration` | "Tap-reveal hold duration" |
| `transcriptBlurSettingsHoldDurationHint` | "How long a tapped cue stays unblurred on touch devices" |
| `transcriptBlurSemanticsOn` | "Blur practice on. Tap or hover to reveal a line." |
| `transcriptBlurSemanticsOff` | "Blur practice off." |

ARB entries MUST include `@key` placeholders for any with parameters
(none in the list above, but the convention must be followed).

---

## C-08 — Test seams

The following seams are guaranteed for tests:

- `TranscriptBlurPreferencesCtrl` exposes the underlying `SettingsDao`
  via the existing `appDatabaseProvider` override; tests override the
  Drift database with `NativeDatabase.memory()` and assert hydration
  + setter persistence.
- `TapRevealHoldCtrl` accepts a `Clock` injection via a private
  constructor parameter so widget tests can advance time deterministically
  (FakeAsync — `tester.pump(Duration(seconds: 4))`).
- `_BlurText` is exported (via `@visibleForTesting`) so widget tests
  can assert the underlying widget tree.
- `cueIdFor` is a pure function and is exercised directly by unit tests.
