# ADR-0021: Multi-language lookup catalog

## Status

Accepted

## Context

The transcript dictionary lookup sheet ([ADR-0019](0019-transcript-dictionary-lookup.md)) was scoped against the user's **profile-native** preference and **learning** preference — both of which are constrained to small curated lists (`kSupportedNativeLanguageTags = ['en-US', 'zh-CN']`, `kSupportedFocusLanguageTags` = 8 entries). As a result, the source / target picker inside the lookup sheet only exposes the two profile-native tags, so a learner importing a Korean (or Japanese, Spanish, French, German, Italian, Portuguese, Russian) transcript cannot pick a meaningful translation target — every lookup silently falls back to either English or Chinese.

The Enjoy worker (`POST /translations`, `POST /dictionary/query`, `POST /chat/completions`) already accepts arbitrary `source` / `target` language codes via `workerLanguageBase` (e.g. `ko-KR` → `ko`, `ja-JP` → `ja`), so the limitation is purely client-side. A bug report on 2026-07-08 called this out as unusable for non-English / non-Chinese learners.

## Decision

1. **Catalog separation** — introduce a **separate** `kSupportedLookupLanguageTags: List<String>` (14 first-wave BCP-47 tags) and an extended `kLookupLanguageLabels: Map<String, String>` map in `lib/core/application/app_language_catalog.dart`. The new catalog is the **only** source of truth for the lookup sheet's source / target option lists. `kSupportedNativeLanguageTags` and `kSupportedFocusLanguageTags` remain untouched, so the Profile / Settings pickers for "native language" and "learning language" keep their narrower choices (no behavior change for the existing profile / settings UI).
2. **First-wave tag set** — `en-US`, `en-GB`, `zh-CN`, `ja-JP`, `ko-KR`, `es-ES`, `es-MX`, `fr-FR`, `fr-CA`, `de-DE`, `it-IT`, `pt-BR`, `pt-PT`, `ru-RU`. Covers the top languages requested by Enjoy Player users as of 2026-07-08 and overlaps with the Azure pronunciation-assessment locale table where relevant, so future TTS / pronunciation work reuses the same set without re-mapping.
3. **Default-target fallback** — extend `resolveLookupTarget` so that, when the user's stored native preference is **not** in the lookup list, the resolver picks the closest supported target via primary-subtag match (e.g. stored native `de-AT` → `de-DE`), then falls back to the first entry in `kSupportedLookupLanguageTags` that is not equal to source and not equal to learning. Existing `coerceNativeIfEqualsLearning` behavior is preserved, so existing en-US / zh-CN users see no behavior change.
4. **Source override** — add `resolveLookupSourceOverride(String?)` so the user can pick a source language inside the sheet even when the active transcript track is `und` / empty / denylisted. The default source is resolved by `resolveLookupSourceLanguage({chromeLanguage, activeTrackLanguage})` (chrome language → active track → learning language) and then canonicalized via the existing `resolveLookupSource`; `resolveLookupSourceOverride` only runs when the user explicitly picks a different source inside the sheet.
5. **Cache invalidation on pair change** — extend `LookupSheetResultCache` with `evictForPair(source, target)` so swapping source / target atomically discards stale results from the prior pair before the new pair's section refresh resolves. Existing params-as-key cache behavior is preserved (every section params struct already includes `sourceLanguage` + `targetLanguage`, so per-pair caching is automatic via the `@riverpod` family).
6. **Worker contract unchanged** — every worker request continues to send `workerLanguageBase(sourceLanguage)` and `workerLanguageBase(targetLanguage)`. Full BCP-47 tags stay on `LookupRequest` and section params for UI display + cache keys but never cross the API boundary.
7. **No persistence** — per-sheet source / target overrides are **not** persisted across app restarts, matching ADR-0019's existing decision.

## Consequences

- **Positive**: Korean / Japanese / Spanish / French / German / Italian / Portuguese / Russian transcripts can now be translated to any of the 14 first-wave target languages, fixing the reported bug.
- **Positive**: Source-language override lets the user correct silent mistranslations caused by `und` track metadata without leaving the player.
- **Positive**: Existing en-US / zh-CN users see no behavior change — `kSupportedNativeLanguageTags` is untouched, default-target resolution preserves `coerceNativeIfEqualsLearning`, and the result cache invalidates correctly per pair.
- **Negative**: ARB grows by ~14 per-language labels (en + zh), so `app_en.arb` and `app_zh.arb` get a small expansion.
- **Negative**: First-wave cap means learners using Arabic / Hindi / Vietnamese / Thai etc. still see "no result" or a worker rejection for those pairs; explicitly out of scope per spec Assumptions and deferred to a follow-up spec.
- **Risk**: Worker may reject a small number of regional variants (e.g. `pt-PT` → Korean on some free tiers). The sheet surfaces a localized `LookupErrorRow` with a Retry affordance rather than silently falling back to English / Chinese (FR-008).
- **Follow-up**: Additional language waves (Arabic / Hindi / Vietnamese / Thai / etc.) may be added in a separate spec; the catalog structure (separate `kSupportedLookupLanguageTags` + labels map) is intentionally additive so future waves do not require re-mapping the picker UI.
- **Follow-up**: Per-sheet override persistence is explicitly **not** introduced here — adding it would change ADR-0019's contract and is intentionally deferred.

## Alternatives considered

- *Reuse `kSupportedFocusLanguageTags` for lookup* — rejected; the focus list is 8 entries (no German / Italian / Portuguese / Russian) and is bound to the learning-language profile preference. Reusing it conflates two unrelated product concepts.
- *Add a single `kSupportedAllLanguageTags` and derive the others* — rejected; the existing native / focus / media lists have different semantics (mutually-exclusive, profile-backed, includes `und`) that don't compose cleanly into one list.
- *Force a profile re-migration when stored native is not in the lookup list* — rejected; over-engineering for a fallback target language, and the picker lets the user override on the spot anyway.
- *Send full BCP-47 to the worker instead of stripping via `workerLanguageBase`* — rejected; would change the existing web-app contract documented in ADR-0019 and could break caching on the server side.
- *Persist per-sheet overrides across app restarts* — rejected; explicitly out of scope per ADR-0019 "not persisted" decision and the spec Assumptions.

## Artifacts

- [spec.md](../../specs/005-multilang-lookup/spec.md) — feature spec
- [plan.md](../../specs/005-multilang-lookup/plan.md) — implementation plan
- [data-model.md](../../specs/005-multilang-lookup/data-model.md) — domain entities
- [contracts/lookup-language-catalog.md](../../specs/005-multilang-lookup/contracts/lookup-language-catalog.md), [contracts/lookup-picker-ui.md](../../specs/005-multilang-lookup/contracts/lookup-picker-ui.md) — contracts
- [research.md](../../specs/005-multilang-lookup/research.md) — resolved unknowns
- [tasks.md](../../specs/005-multilang-lookup/tasks.md) — task breakdown