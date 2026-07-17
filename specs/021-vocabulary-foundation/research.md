# Research: Vocabulary Foundation

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Resolves technical unknowns for P0 (domain + Drift + add from lookup). Product scope already fixed in the spec and [docs/features/vocabulary.md](../../docs/features/vocabulary.md).

## Decisions

### D1. Local-first Drift schema now; sync later (ADR-0052)

- **Decision**: Persist `vocabulary_items`, `vocabulary_contexts`, and `vocabulary_reviews` in Drift (schema **15**). Include optional sync bookkeeping columns (`syncStatus`, `serverUpdatedAt`) on items/contexts for API compatibility, but **do not** extend `SyncEntityType` or enqueue vocabulary in this phase. Review audits remain device-local forever.
- **Rationale**: Spec FR-008/FR-015; feature doc P0/P3 split; ADR-0010 already excludes vocabulary — extend with a new ADR rather than rewriting 0010.
- **Alternatives considered**:
  - Sync in foundation — rejected: larger scope, conflict policy unfinished, blocks shipping capture.
  - Omit sync columns until P3 — rejected: risk of migration churn and id/field drift vs web/API.

### D2. UUID v5 name strings match Enjoy web exactly

- **Decision**: Add helpers in `lib/core/ids/enjoy_ids.dart`:
  - Item: `uuidv5("vocabulary-item:${normalizedWord}:${language}:${targetLanguage}", NAMESPACE)`
  - Context: `uuidv5("vocabulary-context:${itemId}:${sourceType}:${sourceId}:${text.slice(0,100)}:${stableLocatorJSON}", NAMESPACE)`
  - Review audit: random UUID v4 (web parity) on insert.
- **Rationale**: Multi-device sync later must not re-key; namespace already shared (`enjoyUuidNamespaceUrl`).
- **Alternatives considered**: Random item ids — rejected (sync forks). Different name prefix — rejected (web incompatibility).

### D3. Sibling structured media context builder

- **Decision**: Keep `buildVocabularyContext` (returns `String?`) for lookup AI. Add `buildMediaVocabularyContext` (or equivalent) returning `{ text, sourceType, sourceId, locator }` using the same echo / sentence-boundary rules, with locator times in **milliseconds**.
- **Rationale**: Spec FR-013; string-only helper cannot persist locators. Avoid breaking existing contextual-translation callers.
- **Alternatives considered**:
  - Change return type of existing function — rejected: breaks AI path and tests.
  - Persist AI string without locator — rejected: blocks later clip playback / open-in-player.

### D4. Extend `LookupRequest` with media linkage

- **Decision**: Add fields needed to persist a context (at minimum: media id, audio vs video source type, and whatever is required to rebuild locator at add time — either pass structured context at open, or pass session hooks so the CTA can call the structured builder). Prefer building structured context at **open** (or on CTA tap with current echo/time) inside lookup application code, not inside presentation-only widgets.
- **Rationale**: Today `LookupRequest` has only `selectedText`, languages, and string `contextualContext` — insufficient for FR-001/FR-013.
- **Alternatives considered**: Vocabulary feature reading `PlayerController` / transcript providers directly from the CTA widget — rejected: feature↔feature shortcut; harder to test.

### D5. One Unicode-safe normalizer

- **Decision**: Port web `normalizeWord`: lower case, trim, strip characters outside Unicode letters/numbers/spaces (`\p{L}\p{N}\s`). Use for storage, id generation, existence checks, and CTA state. Never use ASCII `\w` for existence.
- **Rationale**: Spec edge case; web button bug to avoid.
- **Alternatives considered**: Match web button’s `\w` for “parity” — rejected: wrong for non-Latin and disagrees with DB normalize.

### D6. Stable locator JSON for context ids

- **Decision**: When hashing context ids, serialize locator with **sorted object keys** (web `JSON.stringify(locator, sortedKeys)`). Persist the locator JSON in Drift using the same canonical field set (`type`, `start`, `duration` for media). Duplicate detection for media: equal `start` and `duration` (not only equal id).
- **Rationale**: Spec FR-007; sync will fork if serialization differs.
- **Alternatives considered**: Dart `jsonEncode` insertion-order only without sorting — rejected if key order can vary across encode paths.

### D7. Repository owns transactions; DAOs stay focused

- **Decision**: `VocabularyRepository.addWithContext` / `deleteItem` / `markReviewed` / `undoLatest` run inside `_db.transaction`. DAOs provide CRUD + due query helpers.
- **Rationale**: Matches library repository pattern; keeps atomicity at the use-case boundary (FR-009, FR-012).
- **Alternatives considered**: Only DAO-level batches — weaker cross-table orchestration for count bumps + audit rows.

### D8. SRS pure domain in foundation (UI later)

- **Decision**: Implement `calculateNextReview`, due predicate, and mark/undo persistence now with unit tests ported from web. Do **not** ship flashcard UI, review options, or keyboard shortcuts in this phase.
- **Rationale**: Spec User Story 4 / FR-011–012; avoids redesigning persistence in P1.
- **Alternatives considered**: Defer SRS until review UI — rejected: higher risk of wrong defaults on create and harder parity later.

### D9. CTA placement on lookup sheet

- **Decision**: Primary control in the lookup sheet chrome (near copy/close) or directly under the selected-term hero — always visible, independent of dictionary section load. States: Add to Vocabulary / Add Context / Already in Vocabulary (remove) / Adding…. Confirm dialog before delete.
- **Rationale**: Spec FR-004/FR-005; ADR-0019 deferred this CTA; web places add near selection actions.
- **Alternatives considered**: Only inside Dictionary section after AI returns — rejected: capture must work offline without AI.

### D10. ADR number 0052

- **Decision**: Record local-first vocabulary Drift schema + out-of-sync-MVP as **ADR-0052** (0051 is YouTube worker discovery).
- **Rationale**: Constitution V; costly schema/identity decision.
- **Alternatives considered**: Fold into feature doc only — rejected for sync/schema irreversibility.

### D11. No new packages

- **Decision**: Use existing `uuid`, Drift, Riverpod. Unicode property regex via Dart `RegExp` with unicode flag as supported by current SDK.
- **Rationale**: Keep supply chain unchanged (ADR-0029 mindset).
- **Alternatives considered**: Extra SRS packages — rejected; algorithm is small and must match web exactly.

## Resolved Technical Context unknowns

| Topic | Resolution |
|-------|------------|
| Schema version | 14 → **15** |
| Sync in P0 | No enqueue; columns reserved |
| Context builder | Sibling structured builder; keep string AI helper |
| Lookup media id | Extend open path / `LookupRequest` |
| ADR id | **0052** |
| Agent context script | Not present in `.specify/scripts` — skipped |

## References (behavioral source of truth)

- Feature contract: `docs/features/vocabulary.md`
- Web: `vocabulary-srs.ts`, `vocabulary-utils.ts`, `id-generator.ts`, vocabulary repositories
- Flutter footholds: `lib/core/ids/enjoy_ids.dart`, `lib/features/lookup/`, `lib/data/db/app_database.dart`
