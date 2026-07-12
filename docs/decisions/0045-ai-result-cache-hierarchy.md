# ADR-0045 — AI Result Cache Hierarchy

**Status**: Accepted  
**Date**: 2026-07-13

**References**: [issue #311](https://github.com/baizhiheizi/enjoy_player/issues/311)  
**Supersedes**: ADR-0039 scope (the `sourceKey` mechanism is preserved but the cache
keying for lookups now uses a unified `AiCacheFingerprint` helper).

## Context

AI results are cached today, but with **four different ad-hoc strategies**:

| Modality | In-memory | Drift | Server |
|---|---|---|---|
| Plain translation | none | none | worker |
| Dictionary | unbounded `Map` | none | worker |
| Contextual translation | unbounded `Map` | none | LLM |
| Auto-translate (per line) | decode memo only | `transcripts.timelineJson` | worker |

Issues:
- **C1**: Plain translation has **no client cache** — every re-open re-hits the worker.
- **C2**: Dictionary/contextual caches are **unbounded** and **process-local only**.
- **C3**: `forceRefresh` is **silently ignored** on the BYOK path.
- **C4**: **No shared cache abstraction** — four keying strategies coexist.

## Decision

1. **Unified two-tier cache**: `AiResultCache<V>` with L1 (bounded LRU+TTL, 256 entries/30 min) and L2 (Drift `ai_cache` table, per-kind cap/age-cutoff).

2. **Shared fingerprint helper**: `AiCacheFingerprint.fingerprint({kind, payload})` — first 32 hex chars of SHA-256 of canonical `<kind>|<sorted kvs>`. One helper for all modalities.

3. **`forceRefresh` enforcement at the cache layer**: the cache layer busts L1+L2 before invoking the loader. Capability implementations no longer interpret the flag for cache purposes.

4. **`linesForRow` memo keyed on content**: decode memo uses `timelineJson` hash, not `updatedAt`, so unrelated Drift table bumps don't force re-decode.

5. **`LookupSheetResultCache` slimmed down**: internal maps removed; `evictForPair` delegates to the new cache hierarchy.

## Consequences

**Positive**
- Translation re-open is instant (warm L1) or sub-250ms (warm L2 after restart) — SC-001/SC-002
- Cache growth bounded by LRU cap + TTL + L2 row cap — prevents long-session memory leaks
- `forceRefresh` works identically on Enjoy and BYOK providers
- Adding a new AI modality requires only a new `AiKind` value + policy entry

**Trade-offs**
- New Drift table `ai_cache` at `schemaVersion: 12` — idempotent migration, no data loss
- `evictForPair` uses SQL LIKE on `payloadJson` (acceptable at <= 4096 rows per kind)
- Auto-translate `sourceKey` remains unchanged (staleness detection, not cache keying)