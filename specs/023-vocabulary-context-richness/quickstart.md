# Quickstart: Vocabulary Context Richness

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide for P2 after implementation. Contracts: [explanation persist](./contracts/vocabulary-explanation-persist.md), [context tab](./contracts/vocabulary-context-tab.md), [media actions](./contracts/vocabulary-media-actions.md).

## Prerequisites

- Phases 021 + 022 behavior available in the tree (add from lookup, `/vocabulary`, review session).
- Signed-in account with dictionary / contextual AI eligibility (or test doubles in widget tests).
- At least one **local** library media item with a transcript so locator-backed contexts can be created.
- Dev machine: Flutter toolchain per [README.md](../../README.md).

## Automated checks

```bash
# From repo root
dart run build_runner build   # if @Riverpod / Drift annotations changed
flutter analyze
flutter test test/features/vocabulary/
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected: analyze clean; vocabulary tests green (persist, session refresh, media-action confirm wiring with mocks).

## Manual scenarios

### 1. Dictionary persist + offline re-open

1. Add a word from transcript lookup (no prior item explanation).
2. Open Vocabulary → Review → start a small session → flip → Dictionary.
3. Fetch dictionary (signed in). Confirm senses render.
4. Force quit app; disable network; reopen → same word Dictionary tab still shows cached result.

**Pass**: SC-001 / explanation-persist C1+C3.

### 2. Contextual translation persist

1. Same session → Context tab → fetch contextual translation.
2. Advance cards; return later (or restart offline) → same context still shows translation.
3. If the item has a second context, confirm the other context was not overwritten.

**Pass**: SC-002 / explanation-persist C2.

### 3. Play segment (stay in review)

1. Context with media locator from local file.
2. Tap Play segment; hear audio for the locator window.
3. Confirm still on review route; rate a card afterward.

**Pass**: SC-003 / media-actions C1. Note rough start latency in PR if > a few seconds.

### 4. Open in player confirm

1. Tap Open in player → **Cancel** → still on same card.
2. Tap again → **Confirm** → review ends; player opens near locator start.

**Pass**: SC-004 / media-actions C2.

### 5. Shadow hand-off

1. From Context tab, Shadow reading → confirm.
2. Land in player with echo active for the span; shadow UI available as with normal echo.
3. Confirm no second player process/engine; prior ratings from the session still in All Words / SRS.

**Pass**: SC-005 / media-actions C3.

### 6. Unavailable paths

1. Item with no context → no crash; no-context copy.
2. (If testable) ebook-shaped context → play/open/shadow unavailable.
3. Offline Dictionary with empty cache → unavailable, not spinner forever.

**Pass**: SC-007 / context-tab C3.

## Out of scope for this quickstart

- Multi-device sync, Anki export, home due widget, ebook reader add.
