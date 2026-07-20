# Research: Vocabulary Sync & Anki Export

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Resolves open product/tech choices for **P3** (sync) and **P4** (Anki). Prerequisites 021–023 remain authoritative for identity, SRS, UI, and explanation shapes.

---

## 1. Implementation order: Anki then sync

**Decision**: Implement **Anki export (P4) first**, then **vocabulary sync (P3)**. Both remain in this feature’s scope; tasks may ship as sequential PRs.

**Rationale**: Parent acceptance marks Anki as required for feature-complete solo use; sync is multi-device and marked “(Later)” in the feature checklist. Anki has zero dependency on sync. Sync needs API + conflict design and a new ADR.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Sync first (strict phase table order) | Delays solo feature-complete; Anki blocked for no technical reason |
| Single mega-PR | Harder review; mixes Pro UX with sync engine changes |

---

## 2. Anki CSV contract (web parity)

**Decision**: Port behavior from Enjoy web `export-csv.ts` + `anki-export-data-standard.md`:

| Rule | Value |
|------|--------|
| Encoding | UTF-8 **with BOM** (`\uFEFF`) |
| Columns | `Front`, `Back`, `Tags` (header comment `#columns:Front,Back,Tags` if web includes it — match web output) |
| Note type | Anki Basic (HTML in fields) |
| Card granularity | One row per **vocabulary item**; contexts merged |
| Tags | `vocabulary` + `{language}-{targetLanguage}` + `status` if not `new` |
| Front | Large word + all context texts joined by `<hr>` |
| Back | Context translations (markdown→HTML), IPA, translation, POS, numbered definitions, examples, source refs — omit missing sections |
| Escaping | RFC-style CSV quotes; `"` → `""` |

**Markdown→HTML**: Use a **simple** converter (web’s `markdownToHtmlSimple` fallback) in Flutter domain — do **not** add unified/remark packages unless already present.

**Rationale**: Behavioral parity with web; keeps Flutter deps lean. Sparse AI cache still exports (empty rich sections).

**Alternatives considered**: APKG generation — out of scope; web uses CSV. Full remark pipeline — unnecessary weight.

---

## 3. Export filters & Pro gate

**Decision**:

- Dialog filters (web `ExportAnkiDialog`): **search** (word/language contains), **status** (`all` or one status), **language** (`all` or one source language).
- Gate with `currentTierProvider` / active Pro (`SubscriptionStatus.isPro` when live status available); Free sees Pro-required copy + navigate to `/subscription`.
- Entry point: All Words toolbar (web list Export button).
- Save/share: reuse mobile `SharePlus` + desktop `FilePicker.saveFile` pattern from `diagnostic_export_flow.dart`.

**Rationale**: Spec FR-002/FR-003; existing tier and export UX patterns.

**Alternatives considered**: Hide Export entirely for Free — rejected; web shows upgrade path. Gate on cached profile tier only — rejected; use live-preferring `currentTierProvider` (ADR-0041).

---

## 4. Vocabulary sync scope & ADR

**Decision**: New **ADR-0054: Vocabulary cloud sync** that:

1. Extends ADR-0010 to admit `vocabulary_item` + `vocabulary_context` metadata sync.
2. States review audits are **never** synced.
3. Defines item conflict = web `resolveVocabularyItemConflict` (SRS-preserving); context = LWW on `updatedAt`.
4. Clarifies that vocabulary **auto-pulls** on signed-in sync (cursor `updatedAfter`), which is an intentional exception to ADR-0013’s “no auto library mirror” for **media files** — vocabulary is a cross-device word book, not local-path media.

Do **not** rewrite ADR-0010 or ADR-0013 text; supersede/extend via 0054.

**Rationale**: Spec FR-011; constitution documentation gate.

**Alternatives considered**: Manual “Cloud → pull vocabulary” only — weaker multi-device UX than web. Sync reviews — forbidden by product (undo is device-local).

---

## 5. Sync engine integration

**Decision**:

| Piece | Action |
|-------|--------|
| `SyncEntityType` | Add `vocabularyItem`, `vocabularyContext` |
| Wire strings | `'vocabulary_item'`, `'vocabulary_context'` (confirm against API/Dexie; align with snake entity folders) |
| Enqueue | From `VocabularyRepository` on item/context create/update/delete; `markReviewed` / explanation updates → **item** or **context** update; never enqueue reviews |
| Upload | `VocabularyApi` POST/DELETE mirrors `AudioApi` shape (`{ vocabularyItem: map }` / `{ vocabularyContext: map }`) |
| Download | Cursor keys `sync.cursor.vocabulary_item` / `sync.cursor.vocabulary_context`; page with `limit` + `updatedAfter` |
| fullSync | Drain queue **and** pull vocabulary entities when signed in |

**Rationale**: Matches existing sync architecture; schema already has sync columns (ADR-0052).

**Alternatives considered**: Separate vocabulary-only sync controller — duplicates retry/auth. Outbound-only vocab (no pull) — fails SC-003 multi-device.

---

## 6. Conflict resolution details

**Decision**: Port web `resolveVocabularyItemConflict`:

1. Compare SRS freshness: prefer side with later `lastReviewedAt`; if only one has it, that side; else higher `reviewsCount`.
2. If local SRS newer: keep local SRS fields; may still adopt newer server **metadata** (e.g. `explanation`) when server `updatedAt` is newer than local SRS timestamp (web behavior).
3. Else: take server row (or merge per web) while preserving any Flutter-only local fields if introduced later (none today).
4. Contexts: standard LWW on `updatedAt`; duplicate locators must not fork (deterministic context ids already).

**Rationale**: Spec FR-009; sync without losing reviews.

**Alternatives considered**: Plain LWW on `updatedAt` for items — can clobber newer SRS with stale metadata edit. Always prefer local — breaks multi-device.

---

## 7. API client

**Decision**: Add `lib/data/api/services/vocabulary_api.dart` extending `RestApi`:

- `GET/POST/DELETE /api/v1/mine/vocabulary_items` (+ `/:id`)
- `GET/POST/DELETE /api/v1/mine/vocabulary_contexts` (+ `/:id`)
- Query: `limit`, `updatedAfter`, optional filters from parent doc

Auth via existing `ApiClient` bearer + refresh. Case conversion already snake↔camel.

**Rationale**: Same pattern as `audio_api.dart`; endpoints documented in vocabulary.md.

---

## 8. Schema / migrations

**Decision**: **No Drift schema bump** for P3/P4. Sync columns and explanation JSON already exist. Reviews keep `syncStatus` but are never queued.

**Rationale**: ADR-0052 designed API-compatible ids/columns for later sync.

---

## 9. Resolved clarifications

| Topic | Resolution |
|-------|------------|
| Ship Anki and sync in one feature? | Yes; Anki first in task order |
| Vocabulary auto-download vs ADR-0013? | Auto-pull vocab; document in ADR-0054 |
| Free export UX? | Show Export → Pro-required + upgrade |
| Markdown stack? | Simple HTML conversion, no new packages |
| Review sync? | Never |

No remaining NEEDS CLARIFICATION for planning.
