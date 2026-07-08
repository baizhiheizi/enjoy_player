# Data Model: Transcript Blur (Practice / Listening-Focus Mode)

**Feature**: [spec.md](spec.md) · [research.md](research.md)
**Phase**: 1 (design)
**Date**: 2026-07-08

This feature introduces **no new Drift tables** and **no new Drift
columns**. It persists exactly two key/value pairs through the
existing `settings` table via `SettingsDao`. All other state is
derived (Riverpod) and not persisted.

---

## 1. Persisted entities (Drift `settings` table)

The Drift `settings` table (key TEXT PRIMARY KEY, value TEXT) already
exists. This feature adds **two static keys** to
`lib/data/db/settings_keys.dart`:

### `prefs.transcript_blur_practice_enabled`

| Field | Value |
|---|---|
| Key (literal) | `"prefs.transcript_blur_practice_enabled"` |
| Type | Boolean encoded as `"true"` / `"false"` |
| Default | `"false"` (toggle starts off; matches "per-user, not per-track") |
| Owner | `TranscriptBlurPreferencesCtrl` |
| Sync | None — local device preference (NOT pushed to server profile) |
| Reset | Cleared by app data reset / "reset preferences" action; not cleared by sign-out |

**Validation rules** (enforced in the notifier setter):

- Reject any non-`"true"` / non-`"false"` value with a warning log and
  fall back to the default (`"false"`).
- Empty / missing value is treated as `"false"`.

### `prefs.transcript_blur_tap_reveal_seconds`

| Field | Value |
|---|---|
| Key (literal) | `"prefs.transcript_blur_tap_reveal_seconds"` |
| Type | Integer encoded as a decimal string (`"1"` … `"15"`) |
| Default | `"3"` (per spec assumption) |
| Owner | `TranscriptBlurPreferencesCtrl` |
| Sync | None — local device preference |
| Reset | Same as above |

**Validation rules**:

- Parsed via `int.tryParse`; any non-integer, negative, zero, or value
  greater than `15` falls back to the default (`"3"`).
- Empty / missing value is treated as the default.

Both keys MUST be added to the `_staticKeys` set in
`settings_keys.dart` so the existing `SettingsKeys.isKnown` predicate
recognizes them.

---

## 2. Riverpod entities (in-memory, not persisted)

These are Dart objects constructed and observed via Riverpod. They are
the single source of truth at runtime; the Drift rows above are only
loaded on startup and re-written on setter.

### `TranscriptBlurPreferences`

Defined in
`lib/features/transcript/domain/transcript_blur_preferences.dart`.

```dart
class TranscriptBlurPreferences {
  const TranscriptBlurPreferences({
    required this.enabled,
    required this.tapRevealSeconds,
  });

  /// Whether the visual blur is currently active in the transcript panel.
  /// Mirrors `prefs.transcript_blur_practice_enabled`.
  final bool enabled;

  /// How long a tap on a blurred cue keeps it revealed before re-blurring.
  /// Always ≥ 1 second, ≤ 15 seconds. Default 3.
  final int tapRevealSeconds;

  static const defaults = TranscriptBlurPreferences(
    enabled: false,
    tapRevealSeconds: 3,
  );

  TranscriptBlurPreferences copyWith({bool? enabled, int? tapRevealSeconds}) =>
      TranscriptBlurPreferences(
        enabled: enabled ?? this.enabled,
        tapRevealSeconds: tapRevealSeconds ?? this.tapRevealSeconds,
      );
}
```

**State transitions** (via `TranscriptBlurPreferencesCtrl`):

| Action | Before | After | Side effect |
|---|---|---|---|
| `setEnabled(true)` | `{enabled: false, tapRevealSeconds: 3}` | `{enabled: true, tapRevealSeconds: 3}` | `settingsDao.setValue('prefs.transcript_blur_practice_enabled', 'true')` |
| `setEnabled(false)` | `{enabled: true, ...}` | `{enabled: false, ...}` | `settingsDao.setValue(..., 'false')` |
| `setTapRevealSeconds(5)` | `{enabled: ?, tapRevealSeconds: 3}` | `{enabled: ?, tapRevealSeconds: 5}` | `settingsDao.setValue('prefs.transcript_blur_tap_reveal_seconds', '5')`; in-flight tap-reveal hold is left to expire naturally — the new value applies to the NEXT tap |

**Identity & uniqueness**: not applicable — single per-user record, not
a collection.

### `TapRevealHold`

Defined in the same domain file. A small immutable record:

```dart
class TapRevealHold {
  const TapRevealHold({required this.cueId, required this.expiresAt});
  final String cueId;       // TranscriptLine identity (startMs + text hash, see below)
  final DateTime expiresAt; // wall-clock UTC
}
```

**Identity & uniqueness**: at most ONE `TapRevealHold` exists per
`mediaId` at any time. Tapping a new cue replaces the hold (the prior
cue re-blurs immediately because its provider's `cueId !=
hold.cueId`). The single Timer that enforces the expiry is owned by
`TapRevealHoldCtrl` and is cancelled on `setHold` and on provider
disposal.

`cueId` is the same identity already used throughout the transcript
feature: `(startMs, endMs)` of the `TranscriptLine` row, with the cue
text as a tie-breaker. (For deterministic identity in tests, see
[contracts/transcript_blur_api.md](contracts/transcript_blur_api.md).)

### `TranscriptCueBlurState` (derived, per-cue)

Not a persisted or stored entity — it is **computed on the fly** by the
`transcriptCueRevealProvider(mediaId, cueId)` family whenever a tile
reads it. The returned `bool` is:

```
revealed = !prefs.enabled
        || localHover            // from the tile's MouseRegion
        || (tapRevealHold?.cueId == thisCue.cueId
            && now < tapRevealHold.expiresAt)
```

The tile widget passes the boolean into a `_BlurText` helper widget
that wraps the body text in `ImageFiltered` (or skips it) accordingly.

---

## 3. Relationships

```
┌─────────────────────────────────────────┐
│ TranscriptBlurPreferences               │  (Drift-backed, keepAlive)
│  - enabled: bool                        │
│  - tapRevealSeconds: int                │
└─────────────────────────────────────────┘
                  │ watched by
                  ▼
┌─────────────────────────────────────────┐
│ TapRevealHoldCtrl  (per mediaId)        │  (Riverpod, autoDispose)
│  state: TapRevealHold?                  │
│  + single Timer per media               │
└─────────────────────────────────────────┘
                  │ watched by
                  ▼
┌─────────────────────────────────────────┐
│ TranscriptCueRevealProvider(mediaId,    │  (Riverpod derived family)
│                                  cueId) │
│  returns bool                           │
└─────────────────────────────────────────┘
                  │ read by
                  ▼
┌─────────────────────────────────────────┐
│ TranscriptLineTile (per visible cue)    │
│  + local _hover: bool                   │
│  renders body text via _BlurText helper │
└─────────────────────────────────────────┘
```

The global toggle is read by **every** tile (cheap: a single
`ref.watch` of `transcriptBlurPreferencesProvider`). The tap-reveal
hold is watched only by the family member whose `cueId` matches the
active hold — other family members do not rebuild.

---

## 4. Volume / scale assumptions

- Up to ~10 000 cues per transcript (worst case for a long podcast /
  lecture). The provider family has one entry per *rendered* cue (the
  `ListView.builder` keeps the active window small), so memory cost is
  bounded by the viewport, not the transcript size.
- Two preferences rows added to the `settings` table (negligible —
  already used for many similar entries).
- Single Timer per open `mediaId` (typically 1, max a handful if the
  user has multiple transcript panels open). Replaced atomically on
  every new tap.

---

## 5. Lifecycle / disposal

- `TranscriptBlurPreferencesCtrl` is `keepAlive: true` — never
  disposed, mirrors `PlayerPreferencesCtrl`.
- `TapRevealHoldCtrl` is `autoDispose` — disposed when no
  `TranscriptLineTile` is currently reading it. The Timer is cancelled
  on disposal so the panel cannot fire an update into a disposed
  provider.
- The `transcriptCueRevealProvider(mediaId, cueId)` family is
  `autoDispose` — disposed when no tile for that cue is mounted.
  Mounting/unmounting follows the `ListView.builder` window, so the
  family has only ~20–40 active entries at a time.

---

## 6. Failure / corruption handling

- If `SettingsDao.getValue` returns an unparseable value for the
  enabled key, the notifier logs a warning via
  `logNamed('transcript_blur')` and uses the default (`enabled: false`).
- If the seconds key is missing or invalid, the notifier uses the
  default (`tapRevealSeconds: 3`).
- The notifier never throws on hydration failure — corrupt state falls
  back to defaults so the app always boots into a usable transcript.
