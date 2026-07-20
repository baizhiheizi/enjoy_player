# Quickstart: Vocabulary Foundation

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide after `/speckit-tasks` / implementation. Contracts and data-model own invariants; this is the runbook.

## Prerequisites

- Signed-in Enjoy Player build with a local or library media item that has a transcript.
- Access to Enjoy web fixtures (optional) under `~/dev/enjoy/apps/web` for parity comparison.
- Dev tree: `bash .github/scripts/validate_ci_gates.sh` baseline green before starting.

## Automated checks

```bash
dart run build_runner build   # after schema 15 / @Riverpod
flutter analyze
flutter test test/core/ids/enjoy_ids_test.dart
flutter test test/features/vocabulary/
flutter test test/features/lookup/   # CTA + structured context builder
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected:

- Normalize / UUID v5 / SRS / due / undo unit tests pass (web parity).
- `addWithContext`: new item; second context increments count; exact duplicate no-op.
- Cascade delete removes item, contexts, and review audits.
- Widget: CTA states transition; confirm cancel leaves data; confirm delete clears item.
- Lookup catalog tests still pass (no ADR-0042 regression).

## Manual — add during playback

1. Open audio/video with a transcript; play to a line with a clear word.
2. Select the word → open dictionary lookup.
3. Confirm **Add to Vocabulary** is enabled without waiting for AI.
4. Tap add → control becomes busy, then **Already in Vocabulary** (or **Add Context** if you seek to a new sentence and re-open).
5. Seek to a different sentence containing the same word → lookup → **Add Context** → contexts increase (verify via later list UI or debug/DAO inspect in dev).
6. Re-open the same locator → **Already in Vocabulary**; count unchanged.
7. Confirm remove → item gone → control shows **Add to Vocabulary** again.
8. Confirm playback continued without multi-second stall (SC-007).

## Manual — language pair separation

1. Add a word with target = native A.
2. Change lookup target language (picker) to B (supported lookup tag).
3. Add the same surface form again → second item (different id), not a merge.

## Docs to update in the same PR

- [docs/features/vocabulary.md](../../docs/features/vocabulary.md) — mark P0 foundation items done / note Flutter status.
- [docs/decisions/0052-vocabulary-local-first-schema.md](../../docs/decisions/0052-vocabulary-local-first-schema.md) — new ADR.
- [docs/decisions/README.md](../../docs/decisions/README.md) — index entry.

## Out of scope smoke (do not block P0)

- Vocabulary page / flashcards / keyboard review shortcuts
- Cloud sync two-device
- Anki export
- Ebook add
