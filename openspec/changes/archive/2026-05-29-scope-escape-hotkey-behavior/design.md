## Context

`AppHotkeysKeyboardListener` registers a global `HardwareKeyboard.addHandler` in `MaterialApp.router`'s `builder`. The `modal.close` action (fixed binding: `escape`) runs an imperative priority ladder before other hotkeys:

1. Close hotkeys cheatsheet (`hotkeysCheatsheetOpen`)
2. Exit desktop window fullscreen
3. Cancel shadow-reading capture via `ShadowReadingHotkeyBus.pulseRecordingCancel()` when `isRecordingActive`
4. Pop leaf then root `Navigator` overlays
5. **`goRouter.pop()`** as final fallback — collapses expanded player when on `/player/:mediaId`

Player collapse via keyboard is separately defined as `player.toggleExpand` (default `Ctrl+Shift+P`). The UI collapse button (chevron-down) correctly calls `collapse()` + `context.pop()` + exits fullscreen; Escape's fallback only pops the route.

Known failure modes (documented in code comments): Escape hit `goRouter.pop()` while a bottom sheet was still open; recording cancel depends on widget-mounted bus listeners and `echoActive` gating; inconsistent collapse side effects.

Constraints: keep `modal.close` non-customizable (Escape locked); Riverpod architecture; no new external dependencies; match existing hotkeys docs parity with web where sensible.

## Goals / Non-Goals

**Goals:**

- Escape dismisses transient UI reliably without collapsing the player as a fallback.
- Explicit collapse paths (button, `player.toggleExpand`) share one implementation: exit fullscreen → `playerUiProvider.collapse()` → pop player route.
- Recording cancel on Escape works as soon as capture begins.
- Non-player routes may still use Escape to pop when no overlay remains.
- Document and test the new semantics.

**Non-Goals:**

- Rewriting the entire hotkey system onto Flutter `Shortcuts`/`Actions` (future improvement).
- Changing default binding for `player.toggleExpand` (remains `Ctrl+Shift+P`).
- Adding an overlay registry / dismiss stack provider (incremental follow-up if bugs persist).
- Mobile system back behavior (unchanged).
- Making `modal.close` user-customizable.

## Decisions

### 1. Remove player collapse from Escape fallback

**Choice:** After steps 1–4 of the `modal.close` ladder, if `goRouter.state.uri.path.startsWith('/player/')`, **return without popping**. Otherwise, if `goRouter.canPop()`, call `goRouter.pop()`.

**Rationale:** Player collapse is navigation, not modal dismissal. Removing the fallback eliminates the class of bugs where overlay detection fails and the player route is popped underneath.

**Alternatives considered:**
- Keep fallback but call unified collapse helper → still collapses on missed overlays; doesn't fix root cause.
- Map Escape to `player.toggleExpand` → toggle semantics wrong (would expand from mini bar context).

### 2. Shared `collapseExpandedPlayer()` helper

**Choice:** Add a small function (e.g. in `player_navigation.dart` or a dedicated `player_collapse.dart` under `application/`) that:

```dart
Future<void> collapseExpandedPlayer(WidgetRef ref, BuildContext context) async {
  await ref.read(windowFullscreenProvider.notifier).setFullscreen(false);
  ref.read(playerUiProvider.notifier).collapse();
  if (context.mounted) context.pop();
}
```

Use from: AppBar collapse buttons, `player.toggleExpand` when on player route, and any future collapse entry points.

**Rationale:** DRY; fixes `playerUiProvider` desync when popping via GoRouter without `collapse()`.

### 3. Recording cancel: synchronous active flag + service-level handler

**Choice:**
- Call `setRecordingActive(true)` **before** async mic start in `ShadowReadingPanel` (or at the moment user initiates record).
- Remove or relax `if (!widget.echoActive) return` guard on `recordingCancel` listener when `_recording` is true locally.
- Optionally move cancel pulse handling closer to the recorder if panel unmount during record is possible.

**Rationale:** Escape must not fall through to route pop because the bus flag lagged or echo gating blocked cancel.

**Alternatives considered:**
- Dedicated `player.cancelRecording` hotkey → clearer but duplicates Escape semantics users expect.

### 4. Navigator overlay dismissal unchanged (for now)

**Choice:** Keep leaf-then-root `Navigator.pop()` probing before any route decision. Do not add overlay registry in this change.

**Rationale:** Minimal diff; removing player fallback addresses the worst bugs. If sheets still misbehave, follow up with registry.

### 5. Escape on player with no dismissible layer = no-op

**Choice:** When on `/player/...` and steps 1–4 do nothing, consume the key event (`return true`) without side effects.

**Rationale:** Prevents Flutter/modal routes from double-handling; avoids accidental propagation. Users learn collapse via visible chevron + cheatsheet.

**Alternatives considered:**
- Return `false` to let other handlers run → risks duplicate behavior.
- Show one-time snackbar hint → optional polish, not required for MVP.

### 6. Documentation and tests

**Choice:** Update `docs/features/hotkeys.md` Escape section. Add focused tests:

- Escape with mock Navigator overlay → pops overlay, player route unchanged.
- Escape on `/player/...` with no overlay → no `goRouter.pop`.
- Escape during `isRecordingActive` → cancel pulse, no pop.
- Escape on non-player pushed route with no overlay → `goRouter.pop`.
- `player.toggleExpand` on player route → calls unified collapse helper.

## Risks / Trade-offs

- **[Risk] Desktop users expect Escape = back out of player** → Mitigation: cheatsheet lists `Ctrl+Shift+P` and collapse button; acceptable **BREAKING** per proposal.
- **[Risk] Some overlays still missed by Navigator probe** → Mitigation: no longer collapses player on miss; worst case Escape no-op instead of catastrophic navigation.
- **[Risk] Recording cancel race on slow mic init** → Mitigation: set `isRecordingActive` synchronously at record intent.
- **[Trade-off] No overlay registry** → Simpler ship; may need follow-up for PopupMenu/Dropdown edge cases.
- **[Trade-off] Escape consumed as no-op on idle player** → Predictable; avoids ambiguous half-states.

## Migration Plan

1. Ship app update with revised `modal.close` ladder and shared collapse helper.
2. No DB migration or settings KV changes (`modal.close` binding unchanged).
3. Update hotkeys cheatsheet strings if Escape description mentions player collapse.
4. Rollback: revert handler logic; no data impact.

## Open Questions

- Should we add a one-time subtle hint when Escape is pressed on idle player (desktop only)? **Proposed:** defer; monitor feedback.
- Should `player.toggleExpand` default change to something more discoverable (e.g. `Backquote`)? **Proposed:** out of scope; separate UX change.
