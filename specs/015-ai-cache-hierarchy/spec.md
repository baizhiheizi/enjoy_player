# Feature Specification: Unify Ad-hoc AI Result Caches into a Bounded Multi-tier Cache

**Feature Branch**: `015-ai-cache-hierarchy`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "Open a PR to resolve issue #311 in remote. Design it well." (GitHub issue #311: `[ai] Unify ad-hoc AI result caches into a bounded multi-tier cache`)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Re-opening the lookup sheet on the same selection is instant (Priority: P1)

A learner who opens the lookup sheet on a phrase, closes it, and re-opens it on the same selection (the most common workflow — see, translate, see again) sees the **Translation** result appear immediately without any network call, even after killing and relaunching the app. Today, Translation has no client cache at all (`lookup_section_providers.dart:16-28`): every re-open re-hits the worker and burns credits. Dictionary and Contextual translation already remember results in-process, but lose them on app restart. The fix is a shared, bounded cache hierarchy that survives restart.

**Why this priority**: Issue #311 gap C1 — this is the single highest-impact user-visible regression: the most repeated lookup flow in the app always re-fetches. It also produces the largest credit savings (Translation is the section that is open on first paint and on every lookup).

**Independent Test**: Can be tested by (a) opening the lookup sheet on a known phrase while online, waiting for the Translation section to render, (b) killing and relaunching the app, (c) opening the lookup sheet again on the same phrase, and observing the Translation text appears before the network spinner would have shown. A unit test asserts the second call skips `translationServiceProvider.translate(...)` entirely.

**Acceptance Scenarios**:

1. **Given** the lookup sheet has previously completed the Translation section for `(selectedText, sourceLanguage, targetLanguage)`, **When** the user closes and re-opens the sheet on the same selection, **Then** the Translation text appears synchronously (no spinner, no `translate(...)` call to the worker).
2. **Given** the app has been killed and relaunched since the previous lookup, **When** the user opens the lookup sheet on the same selection, **Then** the Translation text still appears without a network round-trip (Drift L2 hit).
3. **Given** the same selection has been looked up with two different target languages over time, **When** the user re-opens the sheet on the *original* target language, **Then** the cached translation for that target pair is still served (no cross-target key collision).
4. **Given** the user changes the source or target language via the in-sheet picker, **When** the new pair is looked up, **Then** the cache lookup runs against the *new* pair key and does not leak results from the previous pair above the loading skeleton.

---

### User Story 2 - Bounded cache does not grow unboundedly over long sessions (Priority: P1)

A learner who uses the app for an entire study session — looking up dozens or hundreds of distinct phrases — does not see unbounded memory growth. Today the dictionary and contextual caches are unbounded `Map`s on a `keepAlive` Riverpod provider (`lookup_sheet_result_cache.dart:15-66`). Issue #311 gap C2. The fix replaces them with a bounded LRU + TTL L1 in-memory cache and a Drift L2 with size / age limits.

**Why this priority**: This is the same code path as Story 1; without a bound the app leaks memory and degrades. It is P1 because it directly affects reliability on Windows / Android / iOS / macOS where mobile and laptop RAM is constrained and long sessions are the norm.

**Independent Test**: Can be tested by repeatedly looking up > cache-cap distinct phrases and asserting (a) the cache size never exceeds the configured cap, (b) the LRU tail evicts on overflow, and (c) a TTL-bounded entry expires after its TTL elapses. Unit tests cover cap, LRU eviction, and TTL expiry in isolation.

**Acceptance Scenarios**:

1. **Given** the in-memory L1 cache has capacity `N`, **When** `(N + k)` distinct `(kind, params)` entries are written, **Then** the cache holds at most `N` entries and the `k` least-recently-used entries have been evicted.
2. **Given** an L1 entry was written at time `t` with TTL `T`, **When** `now - t > T` and the same key is looked up, **Then** the cache returns `null` and the caller re-fetches.
3. **Given** Drift L2 storage has accumulated `M` rows for a `kind`, **When** a new row would push the per-kind count past `M`, **Then** the oldest row by `updatedAt` is evicted (LRU at the SQL layer).
4. **Given** the L2 Drift table has accumulated many entries across many sessions, **When** the app starts, **Then** L2 entries older than the configurable `maxAge` are pruned before the first lookup is served from L2.

---

### User Story 3 - `forceRefresh` on the BYOK path actually re-fetches (Priority: P2)

A learner who edits a primary cue, taps the contextual translation **refresh** icon, and watches the result update — even when the BYOK provider is configured. Today `forceRefresh: true` is threaded through `TranslationCapability`, `DictionaryCapability`, `TranslationService`, `DictionaryService`, and `TranslationApi`, but is silently ignored by `ByokTranslationCapability` and `ByokDictionaryCapability` (issue #311 gap C3). The fix makes `forceRefresh` a property of the cache abstraction so all providers honor it consistently, and the BYOK capabilities participate in the same cache hierarchy.

**Why this priority**: This is a correctness bug, not just a UX bug. Users who hit "refresh" and see the same text think the feature is broken. It is P2 because (a) it is contained to two capability implementations and the cache layer and (b) the regression surface is small, but it is a precondition for the BYOK path being a credible tier-1 experience.

**Independent Test**: Can be tested by (a) calling `TranslationService.translate(..., forceRefresh: true)` on a BYOK-configured account and asserting the LLM is called again (no L1/L2 hit), and (b) calling `TranslationService.translate(..., forceRefresh: false)` and asserting the LLM is *not* called twice. Unit tests cover both directions against a fake capability.

**Acceptance Scenarios**:

1. **Given** the cache holds a Translation result for `(text, src, tgt)`, **When** a caller invokes the translation service with `forceRefresh: true`, **Then** L1 and L2 are both busted for that key and the underlying capability is called.
2. **Given** the BYOK provider is configured, **When** the lookup contextual translation section's refresh icon is tapped, **Then** the section shows a loading skeleton and then displays the new LLM response (not the previously cached text).
3. **Given** `forceRefresh: false` (the default), **When** the same key has been recently cached, **Then** no underlying capability call is made (cache hit returns synchronously).
4. **Given** a worker-backed capability (Enjoy provider) and a BYOK capability both expose the same `(text, src, tgt)`, **When** `forceRefresh: true` is sent, **Then** both paths bust the cache identically — no capability silently ignores the flag.

---

### User Story 4 - One keying scheme and one eviction contract for every AI modality (Priority: P2)

A future contributor adding a *new* AI modality (assessment, TTS prompt, ASR hint, etc.) can plug into the cache by writing a one-line `AiResultCache.lookup(key: ..., kind: ..., loader: ...)` call — they do not need to invent a new keying scheme, choose an eviction policy, or pick a TTL. Today four keying strategies coexist (value-equality params, truncated SHA-256 `sourceKey`, deterministic transcript id, no key at all). Issue #311 gap C4. The fix introduces a single `AiResultCache<K, V>` abstraction with one fingerprinting helper, one eviction policy, and one Drift table.

**Why this priority**: This is a refactor whose payoff compounds. Every subsequent AI feature (and the next burst of bugs the team files about "cache misses" or "stale results") gets cheaper. It is P2 because it is mostly internal — the user-visible benefit (Stories 1–3) ships with the same change but is delivered by the P1 stories.

**Independent Test**: Can be tested by (a) writing three fake "modalities" backed by the new cache, asserting that key collisions across `kind`s are impossible (each `kind` is part of the SQL primary key), (b) verifying that the fingerprinting helper produces stable keys for the same input and different keys for different inputs, and (c) confirming the existing auto-translate `sourceKey` logic still passes its test suite after being expressed in terms of the unified helper.

**Acceptance Scenarios**:

1. **Given** the cache is asked for `(kind: "translation", key: "abc")` and `(kind: "dictionary", key: "abc")`, **When** both are populated, **Then** they do not collide — the second write does not evict the first.
2. **Given** a new modality is added that uses the cache, **When** the contributor calls `AiResultCache.lookup(...)` with their own `kind` discriminator, **Then** no change is required to the cache, the LRU policy, the TTL policy, or the Drift schema.
3. **Given** the auto-translate `sourceKey` is now expressed as `AiCacheFingerprint.fingerprint(kind: "auto_translate_line", payload: ...)`, **When** the auto-translate suite runs, **Then** all current behavior is preserved (soft-stale on text edit, hard-stale on track identity change, same-key reuse).

---

### User Story 5 - Transcript `linesForRow` decode memo survives unrelated `updatedAt` bumps (Priority: P3)

A learner who opens a media item, the app decodes the transcript `timelineJson`, and then any unrelated Drift table bump (e.g. a transcript-fetch-state update) shifts the row's `updatedAt` — does not have to re-decode the same track. Today `linesForRow` only memoizes on `(id, updatedAt)` and any `updatedAt` change invalidates the entry (`transcript_repository.dart:139-145`). Issue #311 gap C5. The fix extends the memo to invalidate on `timelineJson` content (cheap hash or string compare) rather than `updatedAt`, or splits the concern: keep an `updatedAt`-keyed invalidation for explicit edits and add a separate LRU of decoded `TranscriptLine` lists keyed on the row id only when the row is *immutable for the session*.

**Why this priority**: This is the smallest of the five gaps and the lowest user-visible payoff. It is P3 because (a) the decode is fast (the timelines we serve are small, JSON parsing is cheap), (b) the `updatedAt` check is correct for explicit edits and the extra work it causes is bounded, and (c) fixing it in the same change as 1–4 is essentially free. We include it in this spec so the cache refactor has a single coherent scope.

**Independent Test**: Can be tested by (a) calling `linesForRow(row)` once, (b) bumping `row.updatedAt` without changing `timelineJson`, (c) calling `linesForRow(row)` again, and asserting the second call returns the same list instance (no re-decode). A second test mutates `timelineJson` and asserts a re-decode happens.

**Acceptance Scenarios**:

1. **Given** a `TranscriptRow` has been decoded into `List<TranscriptLine>`, **When** the same row is requested again *with the same `timelineJson`* (even if `updatedAt` differs), **Then** the memoized list is returned without re-decoding.
2. **Given** a `TranscriptRow`'s `timelineJson` is mutated, **When** `linesForRow(row)` is called, **Then** the new `timelineJson` is decoded and the memo is refreshed.

---

### Edge Cases

- **What happens when a worker call fails after L2 has a stale entry?** The cache layer must surface the error to the caller (so the UI can show a Retry row) without overwriting L1 or L2 with the failed result. The cache must not poison the L2 row with the in-flight failure.
- **What happens when L2 Drift I/O fails (disk full, schema migration in progress)?** The cache must gracefully degrade to L1-only behavior: L2 read failures log and return `null`, L2 write failures log and skip the write. L1 must keep working.
- **What happens with very large `context` payloads for contextual translation?** The cache key fingerprint must include the *normalized* context; a 100 KB surrounding-context string must not become a 100 KB SQL parameter. The fingerprint truncates `context` for the key while preserving the full string in the request payload.
- **How does the cache behave on per-user Drift databases (the `_userId` suffix in `AppDatabase.deviceGlobalDatabaseName`)?** The cache layer treats L2 as scoped to the active `AppDatabase`; when the user signs out and back in, the cache is rebuilt from the new DB. L1 in-memory cache must be cleared on sign-out via the existing `authCtrlProvider` invalidation.
- **How does the cache handle schema migrations?** The new `ai_cache` table ships at `schemaVersion: 12`. Migrations from v11 use a `_addColumnIfMissing`-equivalent pattern that is safe across interrupted launches (mirroring the existing `AppDatabase._runMigrations` discipline).
- **What about clock skew?** L1 TTL uses `DateTime.now()` consistently inside one process; the L2 `updatedAt` is what Drift writes — both are server-free and within-process, so skew between the app and the OS clock cannot affect cache freshness in a meaningful way. (No third-party timestamp dependency.)
- **What about thread / isolate safety?** Drift runs on a background isolate for SQL; L1 reads/writes happen on the main isolate. This is the existing pattern (`LookupSheetResultCache` is main-isolate only) and stays unchanged. No new cross-isolate channels.
- **How does this interact with the worker's server-side cache?** The unified cache is purely a *client-side* layer. Server-side caching (`POST /translations?forceRefresh=true` etc.) remains the worker's contract and is orthogonal to this change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `AiResultCache<K, V>` abstraction MUST live at `lib/features/ai/application/ai_result_cache.dart` (or `lib/core/cache/...` if a shared placement is preferable — pick the one that keeps the feature-first layout clean) and MUST expose a typed `peek(kind, params)`, `remember(kind, params, value)`, `invalidate(kind, params)`, and `forceRefresh` flow that busts both tiers atomically.
- **FR-002**: The cache MUST be a **two-tier** hierarchy:
  - **L1**: bounded LRU + TTL in-memory map (capacity and TTL configurable via constructor; defaults `256` entries and `30` minutes).
  - **L2**: a new Drift table `ai_cache(kind, key, payloadJson, updatedAt)` with primary key `(kind, key)` and a per-kind row-count cap (default `4096`).
- **FR-003**: Plain translation MUST route through the cache (closes issue #311 gap C1). `lookupSheetTranslationProvider` MUST consult L1, then L2, then call `translationServiceProvider.translate(...)` only on a miss.
- **FR-004**: Dictionary and contextual translation caches MUST be migrated from the unbounded `LookupSheetResultCache._dictionary` / `_contextual` maps to the unified cache. The existing `LookupSheetResultCache` class MAY stay as a thin per-pair-eviction helper for the swap / source-target change flow, but its `_dictionary` / `_contextual` maps MUST be removed.
- **FR-005**: `forceRefresh: true` MUST bust L1 *and* L2 for the targeted `(kind, key)` in the BYOK path *and* the Enjoy / worker path. The capability implementations MUST participate in the same cache (no separate forceRefresh semantics per provider).
- **FR-006**: The cache MUST define one fingerprinting helper, `AiCacheFingerprint.fingerprint({required String kind, required Map<String, Object?> payload})`, that produces a stable 32-char hex string. All current ad-hoc keying strategies (value-equality `LookupTextParams.hashCode`, truncated SHA-256 `autoTranslateSourceKey`) MUST be expressible as a call to this helper. The helper MUST be the only sanctioned way to build a cache key going forward.
- **FR-007**: The auto-translate `sourceKey` MUST be expressed in terms of `AiCacheFingerprint.fingerprint(kind: "auto_translate_line", payload: {primaryText, srcLang, tgtLang})`. The current behavior — soft-stale on text edit, hard-stale on track identity change, same-key reuse — MUST be preserved by the auto-translate test suite (existing `auto_translate_request_test.dart` must pass without modification other than the new keying).
- **FR-008**: The new Drift table MUST be added under `lib/data/db/tables/ai_cache.dart`, registered in `AppDatabase` at `schemaVersion: 12`, with an explicit `onUpgrade` step that uses `customStatement` + `CREATE INDEX IF NOT EXISTS` (mirroring the existing `_addColumnIfMissing` discipline) so a partial migration cannot leave the app hanging on a blank window.
- **FR-009**: A new DAO `AiCacheDao` MUST be added under `lib/data/db/app_database.dart` (or split into `lib/data/db/ai_cache_dao.dart` if the file grows), exposing `read(kind, key)`, `upsert(kind, key, payloadJson, updatedAt)`, `delete(kind, key)`, `evictOldestExcept(kind, keep: N)`, and `pruneOlderThan(kind, cutoff)`.
- **FR-010**: L1 MUST enforce both capacity (LRU eviction on overflow) and TTL (entry expires after `now - createdAt > ttl`). Both MUST be testable in isolation.
- **FR-011**: L2 MUST enforce a per-kind row cap (`evictOldestExcept`) and a global age cutoff (`pruneOlderThan`). The defaults MUST be documented in the cache constructor (so a future contributor can find them without reading source).
- **FR-012**: L1 must be safe against the case where the user's `AppDatabase` is rebuilt on sign-in / sign-out (per-user databases). On `authCtrlProvider` state change to signed-out (or signed-in with a new user id), the in-memory L1 must be cleared. L2 is naturally scoped to the active DB.
- **FR-013**: The cache abstraction MUST be entirely synchronous for L1 reads (no `Future`) and asynchronous for L2 reads / writes (returns `Future<void>` or composes into a `Future<V>`). The lookup-sheet and auto-translate call sites are all already async, so the synchronous L1 fast-path can be wrapped in a `Future.value(...)` without ceremony.
- **FR-014**: All new code MUST use `logNamed` for any logging, MUST never call `print`, and MUST never introduce a raw-SQL bypass around the new `AiCacheDao`.
- **FR-015**: The lookup sheet's `LookupSheetResultCache.evictForPair(sourceLanguage, targetLanguage)` flow MUST be preserved as a kind-agnostic "evict every entry for this pair" path: it MUST walk both L1 and L2 and remove every `(kind, key)` whose decoded payload contains `sourceLanguage == X && targetLanguage == Y`. (This is needed for the source/target swap UX in Story 1 acceptance scenario 4.)
- **FR-016**: `forceRefresh` MUST be threaded as a top-level argument through the lookup sheet's three section providers and the auto-translate line translator. The capability interfaces MAY keep the `forceRefresh` parameter for backward compatibility, but the cache layer MUST be the *enforcement* point — capability implementations MUST NOT be the only place that interprets `forceRefresh`.
- **FR-017**: Tests MUST cover (a) L1 hit skips service call, (b) L1 miss + L2 hit returns persisted and backfills L1, (c) L1 + L2 miss calls service and writes both, (d) LRU eviction at capacity, (e) TTL expiry, (f) `forceRefresh` busts both tiers on every provider including BYOK, (g) key collision avoided across `kind`s, (h) L2 Drift row cap and age cutoff, (i) `evictForPair` clears the right entries, and (j) decode memo invalidation on `timelineJson` change but not on `updatedAt` change.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture (constitution § I). The cache abstraction lives under `lib/features/ai/application/` (or `lib/core/cache/` if multiple features use it). It MUST NOT introduce feature-to-feature shortcuts — `lookup_section_providers.dart` calls into the cache, not into `transcript_repository.dart`.
- **QR-002**: Changed behavior MUST have automated tests (constitution § II). The new tests under `test/features/ai/`, `test/features/lookup/`, and `test/features/transcript/` MUST cover the P1 acceptance criteria end-to-end.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns (constitution § III). The cache is internal — no UI changes are introduced by this spec.
- **QR-004**: User-visible flows MUST define measurable performance expectations (constitution § IV):
  - Lookup sheet Translation re-open with a warm cache MUST return synchronously in **< 50 ms p95** on a mid-tier Android device and a 2020-era laptop.
  - Lookup sheet Translation re-open with a cold L1 but a warm L2 (post-restart) MUST return in **< 250 ms p95** on the same hardware.
  - L1 hit ratio over a 30-minute study session MUST be **>= 60%** for repeated lookups on the same phrase (the most common workflow).
  - Memory footprint of the L1 cache MUST stay **<= 8 MiB** at the default 256-entry cap with the largest cached payload (dictionary result + contextual translation + plain translation).
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/` (constitution § V). `docs/features/dictionary-lookup.md` MUST be updated to describe the new cache hierarchy, and `docs/features/ai.md` (or a new section in `docs/features/transcript.md`) MUST describe the auto-translate line cache's participation in the unified hierarchy.
- **QR-006**: A new ADR `docs/decisions/0045-ai-result-cache-hierarchy.md` (placeholder number — pick the next free integer that matches the existing sequence) MUST record the decision to unify the four ad-hoc caches into a bounded two-tier hierarchy, citing issue #311.
- **QR-007**: Drift schema migrations MUST follow the existing `AppDatabase._runMigrations` discipline (no blanket drops, idempotent column adds, no silent hang on partial migration).
- **QR-008**: New code MUST pass `bash .github/scripts/validate_ci_gates.sh` (format + analyze + tests + codegen drift). Generated files (`*.g.dart`) MUST be regenerated via `dart run build_runner build` and committed.

### Key Entities

- **`AiResultCache<K, V>`** — the new shared abstraction. Attributes: `L1Store` (bounded LRU + TTL in-memory map), `AiCacheDao` (Drift L2), `AiCacheFingerprint` (keying helper), `Map<String, KindPolicy>` (per-kind TTL, per-kind L2 row cap, per-kind row age cutoff). The class is generic in `V` but keyed on a single `String kind` discriminator to prevent cross-modality collisions in SQL.
- **`AiCacheFingerprint`** — pure function. `fingerprint({required String kind, required Map<String, Object?> payload})` returns a stable 32-char hex string. Internally normalizes the payload (sorts map keys, trims strings), SHA-256s the canonical UTF-8, and returns the first 32 hex chars (matching the existing `autoTranslateSourceKey` length so existing tests pass without changes).
- **`L1Store<K, V>`** — bounded LRU + TTL. Constructor: `L1Store({required int capacity, required Duration ttl})`. Exposes `peek`, `put`, `invalidate`, `invalidateAll`, and `clear` (for sign-out).
- **`AiCacheRow`** — Drift row. Columns: `kind TEXT NOT NULL`, `key TEXT NOT NULL`, `payloadJson TEXT NOT NULL`, `updatedAt INTEGER NOT NULL`. Primary key `(kind, key)`. Index on `(kind, updatedAt)` to make `evictOldestExcept` and `pruneOlderThan` cheap.
- **`AiCacheDao`** — Drift accessor. Methods: `read`, `upsert`, `delete`, `evictOldestExcept(kind, keep)`, `pruneOlderThan(kind, cutoff)`, `deleteForKind(kind)`. All reads are wrapped to log + return null on failure so the cache never throws to the caller.
- **`AiKindPolicy`** — per-`kind` configuration: TTL, L2 row cap, L2 row age cutoff. Defaults are conservative (30 min / 4096 rows / 30 days); the lookup-sheet / auto-translate call sites may override per-kind.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Re-opening the lookup sheet on the same selection after a previous successful Translation lookup returns the cached text in **< 50 ms p95** (warm L1) on the documented target hardware, with **zero** `translationServiceProvider.translate(...)` calls observed in the network log.
- **SC-002**: Re-opening the lookup sheet after killing and relaunching the app returns the cached text in **< 250 ms p95** (warm L2) with **zero** worker calls, on the same hardware.
- **SC-003**: A study session that issues 100 distinct lookups (one per phrase, no repeats) finishes with L1 size **<= 256 entries** and L2 size (per kind) **<= 4096 rows**; no memory growth past the configured cap.
- **SC-004**: `forceRefresh: true` on the BYOK translation path issues **exactly one** underlying capability call per invocation, on a cache that already contains the target key. (Regression test for issue #311 gap C3.)
- **SC-005**: An existing auto-translate test suite (`auto_translate_request_test.dart`, `auto_translate_repository_test.dart`, `auto_translate_scheduler_test.dart`, `auto_translate_skeleton_test.dart`) passes without modification other than the new keying call, proving the soft-stale / hard-stale / same-key reuse semantics are preserved.
- **SC-006**: Adding a *new* AI modality (any future `kind: "..."` string) requires **zero** changes to the cache class, the LRU policy, the TTL policy, or the Drift schema — only a new `AiKindPolicy` entry in the kind-policy map and a call to `AiResultCache.lookup(...)` at the call site. (Verified by a fixture test that constructs a synthetic modality.)
- **SC-007**: The Drift schema migration from v11 to v12 adds the new `ai_cache` table without data loss, without a manual clear, and without breaking the rest of the schema. Verified by a migration unit test that constructs a v11 DB, runs the v11 → v12 migration, and confirms every pre-existing row in every pre-existing table is preserved.
- **SC-008**: All new code passes `bash .github/scripts/validate_ci_gates.sh` on the existing CI runners. Generated code (`*.g.dart`) is regenerated and committed; `dart format` reports zero diffs.
- **SC-009**: `docs/features/dictionary-lookup.md` and `docs/features/transcript.md` (auto-translate section) describe the new cache hierarchy, with at least one diagram or table showing L1 + L2 + keying + eviction policy.
- **SC-010**: ADR `0045-ai-result-cache-hierarchy.md` is merged, citing issue #311 and the four gaps (C1–C5).

## Assumptions

- The cache layer is **client-side only** — it does not change what the worker caches server-side, does not change the API contract, and does not introduce a new sync queue entry.
- The existing `LookupSheetResultCache` (the wrapper class, not its data) MAY remain as a per-pair-eviction helper. Its internal `_dictionary` / `_contextual` maps MUST be removed; the class MAY keep `evictForPair` as a delegating call to the unified cache.
- The existing `LookupTextParams` / `LookupContextualParams` / `LookupDictionaryParams` MAY keep their value-equality semantics for in-process map use, but the *cache key* is now always the fingerprint (not `params.hashCode`). This is a one-way transition; the old keys are dead code after the change.
- The cache lives at `lib/features/ai/application/ai_result_cache.dart` unless a second feature needs it; if multiple features need it, it is promoted to `lib/core/cache/ai_result_cache.dart`. The promotion decision is recorded in the plan, not the spec.
- Drift schema version bumps from 11 → 12 are safe on all supported platforms. The migration uses the same `_addColumnIfMissing`-equivalent idempotent pattern already in `AppDatabase._runMigrations`.
- The LRU implementation can be a small hand-rolled list-of-keys + map-of-values (matching the `artwork_palette.dart` pattern) — no third-party LRU package is needed. The cap and TTL are small and tested; a `LinkedHashMap`-based LRU is sufficient.
- The new Drift table `ai_cache` is **device-local**; per-user databases (`enjoy_player_<userId>`) get their own L2, scoped by which `AppDatabase` is active.
- The auto-translate `sourceKey` length stays at 32 hex chars so existing fixtures and tests pass.
- The cache does **not** participate in cloud sync (ADR-0010, ADR-0013). L2 rows are intentionally not synced.
- Telemetry / analytics are out of scope for this change. The cache layer logs hits / misses via `logNamed` at `INFO` level so the existing diagnostic paths pick them up.