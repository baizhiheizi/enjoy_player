# Contract: Vocabulary Persistence

**Implements**: FR-002, FR-003, FR-005, FR-008, FR-009, FR-012, FR-013 · [data-model.md](../data-model.md)

## Storage

| Table | Role |
|-------|------|
| `vocabulary_items` | Word-level SRS entity |
| `vocabulary_contexts` | Media/ebook appearances |
| `vocabulary_reviews` | Local undo audit |

Schema version **15** (additive migration from 14). JSON blobs (`explanation`, `locator`) stored as text with typed encode/decode.

Sync columns may exist on items/contexts; **P0 must not** enqueue `SyncEntityType` vocabulary cases or upload reviews.

## `addWithContext` (atomic)

Inputs: raw word, `language`, `targetLanguage`, context `{ text, sourceType, sourceId, locator }`.

Algorithm (web parity):

1. `word = normalizeWord(raw)`; reject if empty.
2. `itemId = enjoyVocabularyItemId(word, language, targetLanguage)`.
3. Load item by id (or by word+language then match targetLanguage).
4. If no item: insert with new-item defaults; `contextsCount = 1`.
5. If item exists: load contexts for `(itemId, sourceType, sourceId)`.
6. Duplicate if same locator:
   - **media:** equal `start` and `duration`
   - **ebook:** deferred UI; if present, equality per web `compareEbookLocators`
7. If duplicate → return `{ item, context, isNew: false }` (no count bump, no insert).
8. Else insert context with deterministic context id; if item already existed, `contextsCount++`; touch `updatedAt`.
9. Return `{ item, context, isNew: true }` when a new context row was written (and `isNewItem` distinguishable if useful for CTA).

Entire sequence runs in one DB transaction.

## Cascade delete

`deleteItem(itemId)` atomic:

1. Delete all `vocabulary_reviews` for item.
2. Delete all `vocabulary_contexts` for item.
3. Delete `vocabulary_item`.

No sync queue writes in P0.

## Mark reviewed / undo

See [vocabulary-identity-srs.md](./vocabulary-identity-srs.md). Persistence must:

- Insert audit before/with item update in one transaction.
- Undo restores pre-image and deletes that audit row only.
- Never mark review rows for cloud sync.

## Media context builder (persistable)

Sibling to string-only `buildVocabularyContext`:

| Output field | Rule |
|--------------|------|
| `text` | Echo ≥2 lines → join those cues; else sentence expansion around active line (same rules as string builder) |
| `sourceType` | `Audio` or `Video` from session |
| `sourceId` | Library media id |
| `locator` | `{ type: media, start, duration }` ms from first→last covered line (or sentence span) |

Must be callable from lookup open / add action with current transcript lines, echo state, and clock.

## Query helpers (foundation)

Minimum:

- Get item by id
- Find item by normalized word + language + targetLanguage (or by computed id)
- List contexts for item (and filter by sourceType/sourceId)
- Due items query (predicate above) — used by tests and later P1 UI
- Latest review audit for item

## Performance

Indexed PK/id lookups; add path should not scan all vocabulary rows. Target: add/existence under ~1s wall time for typical personal libraries (SC-007).

## Out of scope

- Cloud upload/download / conflict merge
- Full-text search index
- Ebook UI writes
