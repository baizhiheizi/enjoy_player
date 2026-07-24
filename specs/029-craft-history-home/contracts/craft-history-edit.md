# C2. Craft history list & edit/save

**Date**: 2026-07-23 | **Feature**: 029-craft-history-home

## C2.1 History provider (NEW)

**Suggested module**: `lib/features/craft/application/craft_history_provider.dart`  
(or extend `library_media_provider.dart` if preferred — Craft UI should import a craft-facing provider)

```dart
/// Stream of library media with provider == 'craft', newest updatedAt first.
final craftHistoryProvider = StreamProvider<List<Media>>(...);
```

**Rules**:
- Filter `provider == 'craft'` only (FR-007).
- Sort by `updatedAt` descending (FR-008).
- React to library watch so deletes/updates refresh the list.

## C2.2 History UI (NEW)

**Modules**: `lib/features/craft/presentation/craft_screen.dart` (+ new history page/sheet)

- `EnjoyPage.actions`: history `IconButton` with tooltip (`craftHistoryTooltip` / similar).
- Opens history surface (preferred: `GoRoute` `/craft/history` under or sibling to `/craft`, or modal route).
- List tiles: label (title/snippet), optional relative time; tap → edit.
- Empty: `EmptyState` + CTA dismissing back to create (FR-013).
- Missing item on tap: calm message; do not crash.

## C2.3 CraftJobState (CHANGED)

**Module**: `lib/features/craft/domain/craft_job_state.dart`

Add:

| Field | Type | Default |
|-------|------|---------|
| `editingMediaId` | `String?` | `null` |

Clear when starting a fresh create loop (`resetForNextCapture` and any “new craft” entry that should not overwrite).

## C2.4 CraftController.loadForEdit (NEW)

**Module**: `lib/features/craft/application/craft_controller.dart`

```dart
Future<void> loadForEdit(String mediaId);
```

**Behavior**:
1. Load craft `AudioRow` + primary transcript; if missing/non-craft → set failure / signal caller.
2. Set `editingMediaId = mediaId`.
3. Prefill texts, languages, voice per [data-model.md](../data-model.md); style → defaults.
4. Land user on an editable stage (Express rewrite or Advanced synthesize) ready to regenerate audio.

## C2.5 MediaLibraryRepository.updateCraftedFromText (NEW)

**Module**: `lib/features/library/data/library_repository.dart`

```dart
Future<String> updateCraftedFromText({
  required String mediaId,
  required String text, // source/raw for sourceText when applicable
  required String learningLanguage,
  required Uint8List audioBytes,
  required List<TranscriptLine> timeline,
  String? voice,
  String sourceFlag = 'craft-direct',
});
```

**Behavior** (FR-012):
- Require existing row with `provider == 'craft'`.
- Replace audio file + update row fields + upsert primary transcript.
- Recompute `md5`; bump `updatedAt`.
- Return **the same** `mediaId`.
- Sync enqueue as update.

**Unchanged**: `importCraftedFromText` insert/dedupe for new creates.

## C2.6 Save branch (CHANGED)

When `state.editingMediaId != null`, Express/Advanced save paths call `updateCraftedFromText` with that id and **must not** early-return a different id from `findExistingCrafted` / hash dedupe.

When `editingMediaId == null`, keep existing import + dedupe behavior.
