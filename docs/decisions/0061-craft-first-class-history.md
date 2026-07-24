# ADR-0061: Craft first-class Home entry, history, and edit

## Status

Accepted

## Context

Craft (ADR-0043, ADR-0060) was reachable only through the Home import
chooser sheet, alongside "From file" and "From YouTube URL". This buried a
core creation flow behind a secondary action and gave Craft items no
dedicated place to revisit: once saved, a Crafted item was indistinguishable
from any other library media — there was no way to see "everything I've
crafted" or edit/re-synthesize an existing item without recreating it from
scratch (and creating a duplicate).

Two additional signals motivated first-class treatment:

1. Craft's Express mode (ADR-0060) — rapid-capture "say something else" —
   naturally produces many small items in quick succession, which increases
   the value of a dedicated history view for browsing and revisiting them.
2. Users occasionally want to fix a mis-transcribed word or tweak the
   translated/rewritten text of an already-saved item without starting over.

## Decision

1. **Home entry point**: Add a `Craft` action (`OutlinedButton.icon`,
   `Icons.auto_awesome_outlined`) to both `EditorialHeader` trailing sites on
   the Home screen, positioned before the existing `Import` button. Extracted
   into a shared private `_HomeHeaderActions` widget so the loaded and
   loading (skeleton) scroll views stay in sync.

2. **Global hotkey**: `c` opens Craft from anywhere (`global.craft` in
   `hotkey_definitions.dart`, scope `global`, customizable). The listener is
   a no-op when already on `/craft` or a `/craft/*` route.

3. **Craft history route** (`/craft/history`): A new `CraftHistoryScreen`
   lists every media item where `Audios.provider == 'craft'`, newest-updated
   first (`craftHistoryProvider`, a `StreamProvider<List<Media>>` built on
   the existing `mediaLibraryRepositoryProvider.watchAll()` — no new DB
   query or schema). Reached via a history `IconButton` in the Craft screen's
   app bar. Tapping an item loads it back into the Craft screen for editing.

4. **Edit-in-place, not duplicate**: `CraftJobState` gains `editingMediaId`
   (nullable). `CraftController.loadForEdit(mediaId)`:
   - Fetches a `CraftEditSource` snapshot (new domain type in
     `lib/features/library/domain/craft_edit_source.dart`, alongside the
     repository it belongs to) via
     `MediaLibraryRepository.getCraftEditSource`. Returns `null` (and
     `loadForEdit` returns `false`) if the row is missing or not a Craft
     item.
   - `CraftEditSource.practiceText` is reconstructed by joining the primary
     (`source = 'ai'`) transcript's timeline segment text — the same
     timeline format used by `saveToLibrary` — rather than reading it from a
     column that doesn't exist for this purpose.
   - Prefills **Express** mode when `sourceFlag == 'craft-express'` and a
     native-language transcript is present; otherwise prefills **Advanced**
     mode with the practice text loaded into the Synthesize tool.
   - `setScreenMode` and `resetForNextCapture` clear `editingMediaId` — mode
     switches or starting a fresh capture always exit edit mode.

5. **Update, not re-import**: When `editingMediaId` is set,
   `CraftController.saveToLibrary` skips `findExistingCrafted` dedupe
   entirely and calls the new
   `MediaLibraryRepository.updateCraftedFromText(mediaId: ...)` instead of
   `importCraftedFromText`. This keeps the same media id, `aid`, and
   `createdAt`, replaces the audio file (deleting the old app-managed file
   if the storage path changed) and the primary transcript, and enqueues a
   `SyncAction.update`. Editing an item never creates a second library
   entry.

6. **No schema changes**: `getCraftEditSource` / `updateCraftedFromText`
   read and write the existing `Audios` / `Transcripts` tables using the same
   `provider = 'craft'` / `source = 'craft-express' | 'craft-translate' |
   'craft-direct'` convention from ADR-0043 and ADR-0060.

## Consequences

- **New domain type**: `CraftEditSource` (`lib/features/library/domain/`).
- **Extended repository**: `MediaLibraryRepository.getCraftEditSource`,
  `MediaLibraryRepository.updateCraftedFromText`.
- **Extended controller**: `CraftController.loadForEdit`; `saveToLibrary`
  branches on `editingMediaId`.
- **New provider**: `craftHistoryProvider`.
- **New screen + route**: `CraftHistoryScreen` at `/craft/history`.
- **Positive**: Craft becomes discoverable without opening the import sheet;
  users can iterate on a crafted item instead of accumulating near-duplicate
  library entries.
- **Neutral**: History has no search, filter, or pagination in this
  iteration — it lists all Craft items in one `ListView.separated`. Revisit
  if Craft libraries grow large enough to need it.

## References

- [ADR-0043: Craft from Text Import](0043-craft-from-text-import.md)
- [ADR-0060: Craft Voice-Express dual-mode redesign](0060-craft-voice-express-dual-mode.md)
- [Feature spec: Craft history + Home entry](../../specs/029-craft-history-home/spec.md)
