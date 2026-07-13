# Quickstart: AI Result Cache Hierarchy (issue #311)

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

This document is the end-to-end validation script for the AI result cache hierarchy change. It is run **after** every task in `tasks.md` is complete and every gate in Phase 9 is green. Each scenario maps to one or more user stories and one or more success criteria in the spec.

---

## Prerequisites

- Working tree clean (all `tasks.md` tasks marked complete).
- `flutter --version` matches `.github/flutter-version`.
- `dart --version` is in the `^3.12.0` range (per `pubspec.yaml`).
- `bash .github/scripts/validate_ci_gates.sh` is green on `main` (so we know any new failure is ours).
- A target device (Android / iOS / macOS / Windows / Linux) for the manual scenario S12.

---

## Automated Validation Scenarios

### S1. LRU capacity enforcement

**Maps to**: US2 (Story 2), SC-003, FR-010, FR-017 (test "LRU eviction at capacity")

**Steps**:

```bash
flutter test test/core/cache/lru_store_test.dart --plain-name 'lru_evicts_oldest_on_overflow'
```

**Expected**: green.

**What it proves**: `L1Store` enforces the configured capacity and evicts the LRU tail on overflow.

---

### S2. LRU TTL expiry

**Maps to**: US2 (Story 2), FR-010, FR-017 (test "TTL expiry")

**Steps**:

```bash
flutter test test/core/cache/lru_store_test.dart --plain-name 'peek_returns_null_after_ttl'
```

**Expected**: green.

**What it proves**: `L1Store` treats entries older than the TTL as misses and evicts them on read.

---

### S3. Fingerprint determinism + kind discrimination

**Maps to**: US4 (Story 4), FR-006, FR-017 (test "key collision avoided across modalities")

**Steps**:

```bash
flutter test test/features/ai/ai_cache_fingerprint_test.dart
flutter test test/features/ai/kind_discrimination_test.dart
```

**Expected**: green.

**What it proves**: `AiCacheFingerprint.fingerprint(...)` is deterministic, returns a 32-char hex string, discriminates `kind`, and is order-independent on payload keys.

---

### S4. Drift DAO correctness + I/O failure handling

**Maps to**: US2 (Story 2), FR-009, FR-011, FR-017 (tests "L2 Drift row cap and age cutoff")

**Steps**:

```bash
flutter test test/data/db/ai_cache_dao_test.dart
```

**Expected**: green. Specifically:
- `read_returns_row`, `read_returns_null_on_miss`, `upsert_inserts_and_replaces`, `delete_removes_row` — basic CRUD.
- `evict_oldest_except_keeps_recent` — LRU eviction at the SQL layer.
- `prune_older_than_removes_old` — age cutoff.
- `delete_for_kind_drops_all_rows` — kind-scoped deletion.
- `io_failure_returns_null_on_read`, `io_failure_is_noop_on_write` — graceful degradation on Drift errors.

**What it proves**: `AiCacheDao` is correct and never throws.

---

### S5. v11 → v12 migration preserves existing data

**Maps to**: FR-008, FR-017, QR-007

**Steps**:

```bash
flutter test test/data/db/ai_cache_migration_test.dart
```

**Expected**: green.

**What it proves**: The Drift schema migration from v11 to v12 adds the `ai_cache` table and index without losing any pre-existing row in any pre-existing table. Idempotent across interrupted launches.

---

### S6. `AiResultCache` end-to-end (L1 hit, L2 hit, miss, forceRefresh, sign-out clear)

**Maps to**: US1, US2, US3 (Stories 1, 2, 3), FR-001..FR-006, FR-013, FR-017 (all tests)

**Steps**:

```bash
flutter test test/features/ai/ai_result_cache_test.dart
```

**Expected**: green. Specifically:
- `lookup_returns_l1_hit_without_calling_loader` — L1 fast path.
- `lookup_returns_l2_hit_and_backfills_l1` — L2 rehydration.
- `lookup_writes_l1_and_l2_on_miss` — write-through.
- `force_refresh_clears_l1_and_l2` — issue #311 gap C3 closed.
- `force_refresh_propagates_loader_error` — loader errors are not swallowed.
- `kinds_do_not_collide` — issue #311 gap C4 closed.
- `evict_for_pair_clears_matching_entries` — issue #311 gap C1 + UX swap behavior.
- `clear_drops_l1_and_l2_on_sign_out` — per-user L1 clearing (R7).
- `prune_applies_per_kind_caps` — L2 row cap + age cutoff (FR-011).
- `loader_error_does_not_pollute_cache` — failed lookups don't poison L1 or L2.
- `l2_io_failure_degrades_to_l1_only` — graceful degradation.

**What it proves**: The cache class wires every layer correctly.

---

### S7. Lookup sheet Translation re-open is instant (US1)

**Maps to**: US1 (Story 1), SC-001, SC-002, FR-003

**Steps**:

```bash
flutter test test/features/lookup/lookup_translation_cache_test.dart
```

**Expected**: green. Specifically:
- Warm L1 hit — `lookupSheetTranslationProvider(params)` returns the cached value without invoking `TranslationService.translate(...)`.
- Cold L1 + warm L2 (after simulated app restart via a fresh `ProviderContainer`) — still no service call.
- Cold L1 + cold L2 — service is called; both tiers are written.
- `forceRefresh: true` busts both tiers.

**What it proves**: Issue #311 gap C1 is closed end-to-end.

---

### S8. Contextual translation refresh actually re-fetches on BYOK

**Maps to**: US3 (Story 3), SC-004, FR-005

**Steps**:

```bash
flutter test test/features/lookup/lookup_contextual_force_refresh_test.dart
flutter test test/features/ai/byok_force_refresh_test.dart
```

**Expected**: green.

**What it proves**: Issue #311 gap C3 is closed end-to-end. `forceRefresh: true` on the BYOK path issues exactly one underlying capability call per invocation, on a cache that already contains the target key.

---

### S9. Auto-translate semantics preserved (US4)

**Maps to**: US4 (Story 4), SC-005, FR-007

**Steps**:

```bash
flutter test test/features/transcript/auto_translate_request_test.dart
flutter test test/features/transcript/auto_translate_repository_test.dart
flutter test test/features/transcript/auto_translate_scheduler_test.dart
flutter test test/features/transcript/auto_translate_skeleton_test.dart
```

**Expected**: green. No test modifications other than the new keying call (R10 / D2 in plan.md).

**What it proves**: The auto-translate `sourceKey` migration to `AiCacheFingerprint.fingerprint(...)` is a drop-in replacement. Soft-stale on text edit, hard-stale on track identity change, same-key reuse all preserved.

---

### S10. `linesForRow` decode memo (US5)

**Maps to**: US5 (Story 5), FR-017, R8

**Steps**:

```bash
flutter test test/features/transcript/transcript_repository_lines_cache_test.dart
```

**Expected**: green.

**What it proves**: `linesForRow` no longer re-decodes when `updatedAt` changes for unrelated reasons. Issue #311 gap C5 closed.

---

### S11. Full gate sweep

**Maps to**: SC-008, QR-008

**Steps**:

```bash
bash .github/scripts/check_dart_format.sh
flutter analyze
bash .github/scripts/check_codegen_drift.sh
flutter test
bash .github/scripts/validate_ci_gates.sh
```

**Expected**: all green.

**What it proves**: The change passes the same cheap gates CI uses. Generated files (`*.g.dart`) are regenerated and committed.

---

## Manual Validation Scenario

### S12. Cold-restart lookup sheet re-open on a real device

**Maps to**: US1 (Story 1), SC-001, SC-002

**Prerequisites**:
- A build of the change installed on a real Android, iOS, macOS, Windows, or Linux device.
- A cloud account signed in (the worker-backed `TranslationService` is the default for non-BYOK users).
- A media item with at least one transcript cue in the library.

**Steps**:

1. Open the media item.
2. Tap a transcript cue (or long-press to select a phrase, depending on the cue type) to open the lookup sheet.
3. Wait for the Translation section to render with a result.
4. Note the Translation text.
5. Close the lookup sheet.
6. **Kill the app** (not just background — force-stop on Android, quit on iOS / macOS, end-task on Windows, `killall` on Linux).
7. **Relaunch the app.**
8. Open the same media item.
9. Tap the same cue (or phrase) to open the lookup sheet.
10. Observe the Translation text.

**Expected**:
- The Translation text appears **synchronously** — no loading spinner, no network indicator.
- The text matches what was rendered in step 4.
- No `TranslationService.translate(...)` call is logged (the network panel in the in-app diagnostics view, or the dev log filtered to `ai_cache`, shows `ai_cache miss kind=translation src=... tgt=...` on the L2-read path, not a worker request).

**What it proves**: SC-001 (warm L1) and SC-002 (warm L2 after restart) hold on a real device.

**Failure mode**: If the Translation text shows a loading spinner, the L2 read failed or the cache lookup skipped. Check the logs filtered to `ai_cache` and verify the `lookup` call returned from L2 (look for `ai_cache hit l2 kind=translation`). The most likely cause is a missed migration or a wrong `kind` discriminator.

---

## Sign-off Checklist

Before opening the PR:

- [ ] All 11 automated scenarios green.
- [ ] Manual scenario S12 verified on at least one target device (Android or macOS is fine).
- [ ] `docs/decisions/0045-ai-result-cache-hierarchy.md` is on disk and references issue #311.
- [ ] `docs/features/dictionary-lookup.md`, `docs/features/transcript.md`, `docs/features/ai.md` are updated.
- [ ] `CHANGELOG.md` has a one-line entry referencing the cache hierarchy.
- [ ] `pubspec.lock` is unchanged (no new dependencies).
- [ ] `*.g.dart` files are regenerated and committed.
- [ ] No `print()` calls added; all logging via `logNamed(...)`.
- [ ] No new `kIsWeb` branches; no new `media_kit` `Player()` instantiations.
- [ ] No raw SQL outside `AiCacheDao`.

When all boxes are checked, push the branch and open the PR with the title:

```
[ai] Unify ad-hoc AI result caches into a bounded multi-tier cache (#311)
```

The PR description MUST include `Closes #311` so the issue auto-closes on merge.