# Research: Craft History & First-Class Entry

**Date**: 2026-07-23 | **Feature**: 029-craft-history-home

## R1. Home Craft control next to Import

**Decision**: Pass a compact `Row` as `EditorialHeader.trailing` on Home (and the loading twin) containing Craft then Import. Craft uses an outlined / tonal button; Import keeps the existing filled Import button so Craft is first-class without demoting Import. Navigate with `context.push('/craft')`.

**Rationale**: `EditorialHeader.trailing` is a single `Widget?`; there is no shared header-actions helper. Import’s Craft row already uses `push('/craft')`. Spec requires Home only (Library header parity deferred).

**Alternatives considered**:
- Replace Import with a menu — rejected (Import remains primary for files/YouTube).
- Add Craft only inside Import — rejected (FR-001).
- Library header Craft in the same PR — deferred by spec Assumptions.

## R2. Global hotkey `c` → Craft

**Decision**: Add `HotkeyDefinition(id: 'global.craft', defaultKeys: 'c', descriptionKey: 'craft', scope: HotkeyScope.global, customizable: true)`. In `AppHotkeysKeyboardListener`, on match: if current path is already `/craft`, return true (consume, no-op); else `goRouter.go('/craft')`. Wire `hotkeys_description.dart` + ARB `hotkeysDescCraft`. Rely on existing `primaryFocusBlocksGlobalHotkeys()` for FR-004.

**Rationale**: Mirrors `global.settings` → `go('/settings')`. Bare `c` does not collide with current player defaults (`a/d/s/e/h/r/v/p/g`). `go` avoids stacking duplicate Craft routes when already there or when navigating from deep stacks.

**Alternatives considered**:
- `push` always — can stack multiple Craft routes; rejected for the “already on Craft” edge case.
- Player-scoped `c` — rejected; Craft is a global create surface (FR-003).

## R3. Craft history data source

**Decision**: Add a Riverpod provider (e.g. `craftHistoryProvider`) that watches `MediaLibraryRepository.watchAll()` (or a thin repo helper) and filters `provider == 'craft'`, sorted by `updatedAt` descending. Present as a Craft-branded list/sheet/route opened from Craft Studio app-bar action. No new Drift table.

**Rationale**: Spec assumes library is system of record; history is a filtered view. Existing badge logic already keys off `provider == 'craft'`.

**Alternatives considered**:
- New `craft_jobs` table — rejected (out of scope; duplicates library).
- Reuse full Home/Library grid with filter chip — weaker Craft branding; harder empty-state for Craft-only.

## R4. Edit prefill (what we can restore)

**Decision**: Add `CraftController.loadForEdit(String mediaId)` that loads the `AudioRow` (+ primary transcript timeline) and prefills:
- Target/learning text ← joined primary transcript text (fallback: title)
- Raw/source text ← `AudioRow.sourceText` when non-empty
- Learning language ← `AudioRow.language`
- Voice ← `AudioRow.voice` when still valid for language; else `defaultVoiceForLanguage`
- Style ← Craft default (`TranslationStyle.auto` in Express / existing Advanced default) — **style is not persisted today**
- Source language ← profile native / current Craft default when not stored
- Mode/stage ← Advanced synthesize-oriented or Express rewrite stage with `translatedText` set (prefer Express rewrite when `source == craft-express` and `sourceText` present; else Advanced with `synthText`)

Track `editingMediaId` on `CraftJobState`; clear on new-create resets (`resetForNextCapture` / explicit “new craft”).

**Rationale**: `Media` domain model drops `sourceText`/`voice`; edit needs DAO/repo access to `AudioRow`. FR-010 allows defaults for missing optional fields.

**Alternatives considered**:
- Persist style in a new column — deferred (schema change not required for FR-010).
- Store source language as secondary transcript — already omitted historically; defaults acceptable.

## R5. Save updates the same item (FR-012)

**Decision**: Add `MediaLibraryRepository.updateCraftedFromText({required String mediaId, ...})` that:
1. Loads existing row; errors if missing or `provider != 'craft'`
2. Writes new audio bytes to storage; updates `localUri`, size, mtime, `md5` (recomputed), `title`, `sourceText`, `voice`, `language`, `source`, `updatedAt`
3. Upserts primary transcript timeline
4. Deletes previous local file when URI changes
5. Enqueues sync **update** (not create-only)

`CraftController.saveToLibrary` / Express save paths: when `editingMediaId != null`, call update and return that id; skip hash-dedupe short-circuit that would return a *different* id. New creates keep `importCraftedFromText` + dedupe unchanged.

**Rationale**: `importCraftedFromText` only inserts or returns existing hash match without updating content. Content-hash ids mean “edit text” would otherwise create a sibling row — violates FR-012.

**Alternatives considered**:
- Delete-then-import — can orphan sync ids / break practice deep links; rejected.
- Force `insertOrReplace` with hash-as-id — changes identity on every text edit; rejected.
- Soft-duplicate + hide old — unexplained duplicates; rejected.

## R6. History UI surface

**Decision**: Craft Studio `EnjoyPage.actions` gets a history `IconButton` (tooltip + l10n). Opens a full-screen route or modal list (`/craft/history` or in-feature sheet) using `EnjoyPage` + list tiles. Empty state uses shared `EmptyState` with CTA to dismiss back to create. Tap tile → `loadForEdit` + pop back to `/craft`.

**Rationale**: App bar is free today; matches “from Craft Studio” (FR-006). Separate route keeps list testable and avoids crowding Express/Advanced body.

**Alternatives considered**:
- Bottom sheet only — fine for phones but weaker for long histories on desktop; route preferred.
- History tab in segmented control — conflicts with Express/Advanced modes.

## R7. ZH branding = Latin “Craft”

**Decision**: Update ARBs:
- `craftScreenTitle` ZH → `Craft`
- `libraryProviderCraftBadge` ZH → `Craft`
- `importCraftFromText` ZH → `Craft…` (short; Home/Import discoverability)
- New `actionCraft` / `homeCraftAction` → `Craft` (EN + ZH) for Home button — do **not** reuse `craftAction` (ZH currently `合成`)
- Verb strings that mean “synthesize” may keep `合成` where they are action verbs, not product name

**Rationale**: Product decision Q1=D. Separating product name from synthesize verb avoids regressing Advanced “Craft”/合成 action labels incorrectly.

**Alternatives considered**:
- `从文本 Craft…` — longer; short `Craft…` preferred per Assumptions.
- Reuse `craftAction` for Home — ZH `合成` is wrong for product face.

## R8. Documentation / ADR

**Decision**: Add ADR-0061 (Craft first-class entry, history edit, Latin Craft in ZH). Update `docs/features/craft.md` Navigation + History/Edit + Localization sections in the same change as implementation.

**Rationale**: Product-scope naming and history-as-filtered-library are costly to reverse (Constitution V).

## R9. Performance

**Decision**: History list derives from existing `watchAll()` stream with in-memory filter/sort; no full-library copy in `build` beyond the filtered list. For large libraries, prefer filtering in the repository/DAO query if profiling shows jank (>~500 craft items); v1 in-memory filter is acceptable for typical learner scale.

**Rationale**: Constitution IV — state budget for scrolling; Craft corpora are usually small vs full library.
