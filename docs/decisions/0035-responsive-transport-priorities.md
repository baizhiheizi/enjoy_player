# ADR-0035: Responsive transport priorities and collapsed-expand recovery

## Status
Accepted

## Context
The narrow (≤720px) `GlobalTransportBar` previously packed **previous** and **next** as a single inseparable “prev/next” slot and treated them as always-on. At phone widths (e.g. 320px) this forced the five practice-critical controls to fight for the remaining space, and previous/next could only drop together. Worse, on the collapsed mini transport the only expand affordance was the `open_in_full` icon button — which was the **first** control dropped as width shrank, leaving users at the narrowest widths in a dead-end (no visible way to reach the full player, only swipe-down-to-dismiss).

Two problems to solve:

1. **Always-on practice set** — play/pause, echo, blur, subtitle (cc), and speed must be reachable at every supported width because they are the core of the language-learning loop. Previous/next/volume are secondary (transcript-line taps and hotkeys also navigate).
2. **Collapsed expand dead-end** — when the expand icon is dropped for width, there must still be a discoverable, accessible way to expand to the full player.

## Decision

### 1. Strict-priority budget packing (C1–C6)
Replace the coupled “prev/next always-on” model with a **pure** resolver, `resolveNarrowTransportBudget` (removed with the global transport bar in [ADR-0093](0093-duet-design-language.md)), that:

- Computes a fixed **always-on base cost** = play ring + echo + blur + cc + speed + spacing.
- Treats the remaining controls as independently droppable items, each with a priority and a width cost, and **greedily packs** them highest-priority-first into the remaining budget.
- Exposes independent `showPrevious` / `showNext` flags (previous and next drop independently), plus `showVolume` and `showFullscreen`.

**Priority order** (highest → lowest, i.e. last-dropped → first-dropped): fullscreen → volume → next → previous → expand. Thus the drop sequence as width shrinks is: **expand → previous → next → volume → fullscreen.**

Why previous drops before next: both navigate by transcript line, but **next** (continue forward) is the more common direction during shadow-reading practice, so it is retained longer.

The resolver is a **pure function of width + capability flags** — no widget tree, no side effects — so it is exhaustively unit-tested with a width sweep and assertions on each contract (always-on invariant, eligibility, drop order, strict priority with no inversion, determinism).

### 2. Neutral-area tap-to-expand (E1–E7)
When collapsed (not on `/player/...`) and narrow, the controls row is wrapped in [`EnjoyTappableSurface`](../../lib/core/interaction/enjoy_tappable.dart) with `onTap: openPlayerRoute(...)`. The `IconButtons` inside the row win the gesture arena, so **only taps on neutral space** (the `Spacer` between clusters, not on a button or the seek strip) trigger expand. This means the expand affordance survives even at widths where the expand icon is dropped — closing the dead-end.

The affordance is **absent on the `/player/...` route** (already expanded) and reuses the existing `transportExpand` semantics label, so no new l10n keys are required. The existing `player.toggleExpand` hotkey already routes through `openPlayerRoute` when not on the player route, keeping keyboard parity.

## Consequences
- **Positive**: The five core practice controls are guaranteed visible at every supported width; previous and next degrade gracefully and independently; the mini-to-full expansion is always reachable.
- **Positive**: The resolver being pure makes the layout contract machine-checkable — 79 unit tests pin C1–C6, and widget tests cover the US1–US4 user stories at representative widths (320/375/430/800) on both library and player routes.
- **Negative**: At the narrowest widths (e.g. 320px), previous/next are hidden from the bar — users must use transcript-line taps or hotkeys to navigate. This is acceptable because line-tapping is the primary navigation on narrow devices anyway, and the transcript line is the dominant target.
- **Trade-off**: `warnIfMissed: false` is used on the one widget test that taps a transparent `Spacer` to target the parent surface; this is intentional and documented in the test because the Spacer is empty space whose hit target is the parent by design.
- **Follow-up**: If a future layout needs different priorities (e.g. a new control), extend the resolver’s droppable list + priority — no widget-tree changes required.
