## Context

[`GlobalTransportBar`](../../../lib/features/player/presentation/widgets/global_transport_bar.dart) renders a glass bottom transport for all active playback sessions. Layout splits at `EnjoyThemeTokens.breakpointTranscriptSideBySide` (720px):

- **Wide** (`hideBottomMediaInfo == false`): play + full transcript cluster (prev, next, replay) + artwork/meta + secondary tools in a horizontally scrollable row.
- **Narrow** (`hideBottomMediaInfo == true`): single 56px-tall control row with a `LayoutBuilder` that reserves ~58px for the play ring, counts secondary icons at **48px** each (+16px slack for the speed button’s inner padding), and only shows transcript controls when `remaining >= 48 * 3`.

That all-or-nothing gate hides prev/next on typical phone widths (375–414px) while still showing echo, CC, speed, and volume. Product direction: **prev/next are P1**; **replay is P4** (transcript line tap and hotkeys suffice on mobile). **No second row** and **no overflow menu**.

Line actions are implemented in [`PlayerInteractions`](../../../lib/features/player/application/player_interactions.dart) (`prevLine`, `nextLine`, `replayLine`). Disabled state when `!hasTranscriptLines` (unchanged).

## Goals / Non-Goals

**Goals:**

- Show **prev** and **next** on narrow layouts whenever `hasTranscriptLines` is true, without `Row` overflow down to **320px** logical width on the player route.
- Hide **replay** on narrow layouts; keep replay on wide layout and via hotkeys everywhere.
- Use **compact slots** on narrow (~40px icon buttons, ~52–58px play ring budget) in a **single row**.
- Apply a **fixed defer order** when width is still insufficient: replay → expand (mini only) → volume → never prev/next (when transcript exists).
- Add widget tests at **320 / 375 / 430** px to lock visibility and prevent regressions.

**Non-Goals:**

- Redesigning progress strip, play ring visuals, or glass chrome.
- Moving speed/CC/echo into a sheet or `⋯` menu.
- Changing `PlayerInteractions` seek/replay semantics or hotkey bindings.
- Tablet wide layout changes beyond keeping current wide behavior.

## Decisions

### 1. Replace boolean `showTranscriptControls` with tiered flags

**Decision:** Compute separate booleans in the narrow `LayoutBuilder`:

| Flag | Meaning |
|------|---------|
| `showPrevNext` | Render prev + next `IconButton`s |
| `showReplay` | Render replay `IconButton` (narrow: always false) |

Wide layout continues to render all three without width gating.

**Rationale:** Decouples P1 (prev/next) from P4 (replay). Avoids requiring 144px for any line navigation.

### 2. Narrow slot constants

**Decision:**

- `kNarrowIconSlotWidth = 40.0` (budget + `SizedBox` width on `IconButton` wrappers if needed)
- `kNarrowPlayRingWidth = 54.0` (44px circle + horizontal padding; aligns with [`TransportPlayRingButton`](../../../lib/features/player/presentation/widgets/transport/transport_play_ring_button.dart))
- `kNarrowSpeedSlotExtra = 12.0` (speed button inner padding; was 16 at 48px scale)
- `kNarrowLayoutSlack = 8.0`

Keep `iconSize: 22` (or 20 on narrow if needed for visual balance).

**Rationale:** Prior attempt at 40px slots caused overflow when bundled with replay + 48px secondary; dropping replay and tiered defer makes 40px viable. Comments in code document the prior 48px Material tap-target rationale.

**Alternative considered:** 36px slots — rejected; too close to minimum touch comfort without strong need.

### 3. Priority-based defer order (narrow only)

**Decision:** After reserving play + prev + next (+ replay if wide), allocate secondary slots left-to-right in the existing order: echo, CC, speed, volume, expand (if `!onPlayer`). When budget is exhausted, drop from the **end** of this list first:

1. **expand** (mini transport only)
2. **volume**
3. Never drop echo, CC, speed, or prev/next when transcript lines exist

Replay is not in the narrow secondary list; it is omitted entirely on narrow (not deferred).

**Rationale:** Matches user preference: no `⋯` menu; expand less critical than line nav on mini player; volume redundant with hardware keys on phones.

**Mini vs player:** `secondaryCount` differs by one (expand). Budget function takes `onPlayer` and `showFullscreenTransport` (desktop video only) as today.

### 4. Visual grouping (optional polish)

**Decision:** Wrap `[prev, playRing, next]` in a `Row` with `mainAxisSize: min` and reduced gap (4px) between line controls; keep existing `Spacer()` before secondary cluster.

**Rationale:** Communicates “line transport” without extra width. Low risk; can ship in same PR.

### 5. Wide layout unchanged

**Decision:** No width calculator on wide branch; `primaryTransport` = play + all three transcript controls; secondary scrolls horizontally.

**Rationale:** Already works; replay stays for mouse-driven desktop users.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Row overflow on 320px mini + expand + all tools | Defer expand then volume first; widget test at 320 |
| 40px tap targets below Material 48dp guideline | Document exception for dense transport; tooltips + hotkeys |
| Users miss replay on mobile | Document tap-active-line in `player.md`; hotkeys on desktop |
| Budget drift when adding new transport buttons | Centralize budget helper (private function or small class in `global_transport_bar.dart`) |

## Migration Plan

- Ship in one PR; no data migration.
- Rollback: revert `GlobalTransportBar` layout branch only.

## Open Questions

- None blocking implementation. Optional follow-up: show replay on narrow only above ~480px if spare budget (not in scope unless requested during apply).
