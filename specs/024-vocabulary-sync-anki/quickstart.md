# Quickstart: Vocabulary Sync & Anki Export

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide after implementation. Contracts: [Anki export](./contracts/vocabulary-anki-export.md), [sync](./contracts/vocabulary-sync.md), [API](./contracts/vocabulary-api.md).

## Prerequisites

- Phases 021–023 available (add/review/explanations).
- Signed-in account for sync tests; Pro subscription (or test override of tier) for Anki export.
- Second device **or** ability to simulate remote store / inspect API + wipe local DB for pull verification.
- Dev machine: Flutter toolchain per [README.md](../../README.md).

## Automated checks

```bash
# From repo root
dart run build_runner build   # if @Riverpod / API provider wiring changed
flutter analyze
flutter test test/features/vocabulary/ test/features/sync/
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected: analyze clean; Anki CSV + Pro gate + conflict/enqueue tests green.

## Manual scenarios

### 1. Pro Anki export (SC-001)

1. Seed several words with contexts; fetch dictionary/contextual AI on at least one item.
2. Ensure Pro tier (live subscription).
3. Vocabulary → All Words → Export to Anki.
4. Apply status or language filter; export; save/share file.
5. Open CSV (or import into Anki with HTML allowed): columns Front/Back/Tags; BOM present; filtered count matches; rich Back sections appear only where cache exists.

**Pass**: Anki-export C1, C3, C4.

### 2. Free Pro gate (SC-002)

1. Free tier account (or force free via test).
2. Tap Export to Anki → see Pro-required copy + upgrade to `/subscription`.
3. Confirm no CSV file is produced.

**Pass**: Anki-export C2.

### 3. Sparse cache export (SC-005)

1. Export items that never fetched AI explanations.
2. CSV still generates; Back omits missing rich sections (no fabricated text).

**Pass**: SC-005.

### 4. Sync add across devices (SC-003)

1. Device A (signed in): add a new word + context; wait for queue drain (or trigger sync).
2. Device B (same account, empty or stale local vocab): sign-in / sync pull.
3. Confirm item appears with same id and context text.

**Pass**: sync C1.

### 5. SRS-preserving merge (SC-003 / sync C2)

1. Same item on A and B with different `lastReviewedAt` / `reviewsCount`.
2. Sync both directions.
3. Confirm the newer SRS side wins; id unchanged.

**Pass**: sync C2. (Automated unit test of conflict resolver is the primary proof; manual if two devices available.)

### 6. Reviews stay local (SC-004)

1. Rate cards on A (undo stack works).
2. Sync to B.
3. Confirm B has item SRS state but **no** remote review-audit dependency; undo on A still works locally only.

**Pass**: sync C4 / SC-004.

### 7. Offline resilience (sync C5)

1. Airplane mode: add/review words.
2. Restore network; sync drains.
3. Local rows intact throughout; remote catches up.

**Pass**: sync C5.

## Out of scope for this quickstart

- Home due widget, ebook add, tags/batch import, Notes content.
- Media library auto-mirror (unchanged by ADR-0013).
