# Data Model: Orientation Policy & Player Content Layout

**Feature**: 026-orientation-layout-polish | **Date**: 2026-07-20

This feature is mostly behavioral. There are no new Drift tables or preference keys. The “model” is the small set of domain values used by pure helpers and the player layout.

---

## DeviceFormFactor

Logical device class for orientation policy.

| Value | Meaning | Orientation policy |
|-------|---------|-------------------|
| `phone` | Mobile, shortest side &lt; 600 logical px | Portrait-only preferred orientations |
| `tablet` | Mobile, shortest side ≥ 600 logical px | All orientations allowed |
| `desktop` | Windows / macOS / Linux | No `SystemChrome` orientation lock |

**Inputs to resolve**:

| Field | Type | Notes |
|-------|------|-------|
| `platform` | `TargetPlatform` | From `defaultTargetPlatform` |
| `shortestSideLogical` | `double` | `min(width, height)` of the primary view's **display** in logical pixels |

**Validation**:

- Desktop platforms ignore `shortestSideLogical` for classification (always `desktop`).
- On mobile, `shortestSideLogical` must be finite and &gt; 0; if unavailable at bootstrap, return `null` and **defer** the orientation lock (do not guess phone — that pillarboxes tablets).

---

## AppWindowOrientation (derived)

Not stored. Derived from a size:

| Condition | Orientation | Player content layout |
|-----------|-------------|------------------------|
| `width > height` | landscape | side-by-side |
| `height >= width` | portrait (includes square) | stacked |

---

## PlayerContentLayout

| Value | Presentation |
|-------|----------------|
| `stacked` | Video (16:9 stage) above transcript |
| `sideBySide` | Video column + draggable transcript column |

**Relationships**:

- Chosen solely from `AppWindowOrientation` of the **player layout constraints** (not from `DeviceFormFactor`, not from `breakpointTranscriptSideBySide`).
- `DeviceFormFactor.phone` implies the window stays portrait → effectively always `stacked` while the phone lock holds.
- Side-by-side still honors existing transcript min width (360, capped) and persisted `splitPx`.

---

## Persistence

| Item | Change |
|------|--------|
| Player `splitPx` preference | Unchanged; still used when side-by-side is active |
| New settings / Drift columns | None |

---

## State transitions

```text
[Bootstrap]
  → resolve DeviceFormFactor
  → apply preferred orientations (phone/tablet) or skip (desktop)

[Player LayoutBuilder rebuild on size/orientation change]
  → derive AppWindowOrientation from constraints
  → choose PlayerContentLayout
  → rebuild Row or Column; keep engine + transcript state
```
