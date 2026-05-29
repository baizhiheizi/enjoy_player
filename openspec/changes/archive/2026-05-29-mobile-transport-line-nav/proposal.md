## Why

On narrow viewports (≤720px), the global transport bar hides **previous line** and **next line** controls whenever the row cannot fit all three transcript buttons (prev, next, replay) at 48px slots alongside play and secondary tools. That gate removes line navigation on most phones (roughly &lt;430px logical width), even though prev/next are core to language-learning workflows. Users can still tap transcript lines to seek, but losing dedicated transport buttons makes line stepping awkward while reading or in echo mode.

## What Changes

- **Restore prev/next on narrow layouts** when a primary transcript is available, using a **priority-based width budget** instead of an all-or-nothing transcript cluster.
- **Drop the replay bar button on narrow layouts** (replay remains available via transcript line tap and desktop/hotkeys); replay is lowest priority among line controls.
- **Use compact control slots on narrow layouts** (~40px) with existing `VisualDensity.compact`, preserving a **single-row** bar (no second row, no overflow “more” menu).
- **Defer lower-priority tools when still tight**: on mini transport, defer expand before prev/next; on the tightest widths, defer volume (and expand on mini) before echo, CC, speed, or prev/next.
- **Keep wide layout behavior** (&gt;720px): full control set including replay; secondary tools scroll horizontally when needed.
- **Document and test** width breakpoints (320 / 375 / 430 logical px) to prevent `Row` overflow regressions.

## Capabilities

### New Capabilities

- `global-transport-bar`: Narrow-layout control visibility, priority ordering, and width budgeting for line navigation and secondary transport actions.

### Modified Capabilities

<!-- No existing openspec specs define transport bar layout. transcript-loading CC behavior unchanged. -->

## Impact

- **Presentation**: `global_transport_bar.dart` (narrow `LayoutBuilder` budget, tiered visibility flags, compact slot sizing).
- **Docs**: `docs/features/player.md` (line-level transport on mobile); optional note in `docs/features/app-ui.md`.
- **Tests**: Widget tests for transport control presence at representative widths; optional golden/layout overflow guard.
- **Localization**: None (existing strings for prev/next/replay).
- **Hotkeys**: Unchanged (`player.prevLine`, `player.nextLine`, `player.replayLine` remain on desktop).
