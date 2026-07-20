# ADR-0052: Vocabulary local-first Drift schema

## Status

Accepted

## Context

Enjoy web already ships a local-first spaced-repetition vocabulary book with deterministic UUID v5 identities and API-shaped entities. Flutter needs the same capture path (add from transcript lookup) without waiting for cloud sync. ADR-0010 / ADR-0013 cover audio/video/recording sync only — vocabulary must not be bolted into that MVP without a dedicated conflict policy.

## Decision

1. Persist **`vocabulary_items`**, **`vocabulary_contexts`**, and **`vocabulary_reviews`** in per-user Drift (`AppDatabase` schema **15**).
2. Use Enjoy UUID v5 name strings and Unicode-safe `normalizeWord` matching web so future sync does not re-key data.
3. Keep optional **sync bookkeeping** columns on items/contexts (`syncStatus`, `serverUpdatedAt`) for API compatibility, but **do not** extend `SyncEntityType` or enqueue vocabulary in this phase.
4. **`vocabulary_reviews`** are device-local undo audits only — never uploaded.
5. Ship **Add to Vocabulary** on the dictionary lookup sheet (media contexts only) as the first user-visible surface; review UI, Anki export, and ebook add remain later phases.

## Consequences

- Capture and local SRS math work offline without network.
- Sync requires a new ADR (conflict rules for SRS-preserving merge) before enabling queue entity types.
- Does not rewrite ADR-0010; vocabulary remains out of sync MVP until that follow-up ADR.

## References

- Feature: [docs/features/vocabulary.md](../features/vocabulary.md)
- Spec: `specs/021-vocabulary-foundation/`
- Related: [ADR-0010](0010-cloud-sync-mvp.md), [ADR-0019](0019-transcript-dictionary-lookup.md), [ADR-0042](0042-multi-language-lookup-catalog.md)
