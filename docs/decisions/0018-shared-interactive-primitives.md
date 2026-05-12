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

## Consequences

- **Pros**: One visual/tactile language; easier a11y sweeps (focus + cursor + tooltip patterns); fewer ad-hoc `FilledButton` variants.
- **Cons**: Slight indirection vs raw Material widgets; refactors touch many files when tightening consistency.
- **Follow-up**: Keep migrating remaining `InkWell`/`GestureDetector` islands; extend primitives only when a third consumer needs the same behavior.
