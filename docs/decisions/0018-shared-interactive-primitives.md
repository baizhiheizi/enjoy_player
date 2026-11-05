# ADR-0018: Shared interactive primitives (EnjoyTappable, Haptics, EnjoyButton)

## Status

Accepted

## Context

The player shell mixed raw `InkWell` / `GestureDetector` patterns with bespoke hover cards (e.g. library tiles), so ripples, focus rings, desktop hover, and haptics were inconsistent. Duplicated `FilledButton` call sites also made it easy to skip light haptic feedback on primary actions.

Note: ADR numbering skips **0017** for this topic because **0017** is already used for Azure pronunciation assessment.

## Decision

Introduce a small **interaction kit** under `lib/core/interaction/` and shared buttons/cards under `lib/core/theme/widgets/`:

- **`Haptics`** — centralizes `HapticFeedback` calls, respects `MediaQuery.disableAnimations` and mobile-only guards.
- **`EnjoyTappableSurface` / `EnjoyTappableIcon`** — `Material` + `InkWell` + hover/focus affordances + optional `Haptics.wrapTap`.
- **`EnjoyButton`** — thin typed wrappers (`primary`, `secondary`, `ghost`, `destructive`) over Material 3 buttons with haptics on press.

Presentation code should **prefer these primitives** for new work and migrate legacy surfaces opportunistically (transport, settings rows, library tiles, notices).

## Amendment — 2026-11-05: shared anchored popover route

The player parks its video surface under anchored popovers (ADR-0066). That pattern was hand-rolled as three near-identical `PopupRoute` subclasses — the player's ⋯ More menu, the wide Subtitles & display popover, and the right-edge margin drawer — each repeating the same barrier semantics, anchored placement, and fade (+ optional slide) transition. Only the label, durations, insets, and content differed, and the copies had already drifted apart in transition timings.

**Decision**: add **`AnchoredPopoverRoute<T>`** to `lib/core/theme/widgets/`. It owns the whole skeleton — a transparent dismissible barrier, the `barrierLabel` that makes the barrier reachable by screen readers, the anchored `Align` + insets, and the fade / slide transition — and parameterizes what actually varies: `barrierLabel`, `alignment`, `insets`, the transition durations, the slide offset and curve, and the content builder. The three call sites now push it directly; their content widgets (`PlayerMoreMenuPanel`, `SubtitleTrackPickerSheet`, the margin panel) are unchanged.

A fourth anchored popover is now a one-liner instead of a copy of the skeleton.

## Consequences

- **Pros**: One visual/tactile language; easier a11y sweeps (focus + cursor + tooltip patterns); fewer ad-hoc `FilledButton` variants; one place for popover motion and barrier semantics.
- **Cons**: Slight indirection vs raw Material widgets; refactors touch many files when tightening consistency.
- **Follow-up**: Keep migrating remaining `InkWell`/`GestureDetector` islands; extend primitives only when a third consumer needs the same behavior.
