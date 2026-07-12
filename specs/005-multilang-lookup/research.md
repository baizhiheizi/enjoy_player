# Phase 0 Research: Multi-language transcript lookup & translation

All Technical Context unknowns from [plan.md](./plan.md) are resolved below before Phase 1 design.

## 1. Catalog separation: lookup languages vs. profile / focus / media languages

- **Decision**: Introduce a new **separate** `kSupportedLookupLanguageTags` catalog in `lib/core/application/app_language_catalog.dart`, with a matching `kLookupLanguageLabels` map for human-readable per-language labels. Leave `kSupportedNativeLanguageTags` (2 tags, profile "native" preference) and `kSupportedFocusLanguageTags` (8 tags, profile "learning" preference) untouched, so the Profile / Settings pickers continue to offer the original narrow choice. Lookup sheet picks from the new, wider catalog only.
- **Rationale**: The bug is purely client-side — the worker already accepts arbitrary `sourceLanguage` / `targetLanguage` (it only requires `workerLanguageBase` to strip the tag to its base code, e.g. `ko-KR` → `ko`). The UI is what hard-caps the choice to 2 native tags via `LookupLanguagePickerRow` iterating `kSupportedNativeLanguageTags`. Widening **only the lookup** catalog avoids any unintended regression in profile / settings surfaces that have already shipped against the narrow choice. Aligns with spec FR-009.
- **Alternatives considered**:
  - *Reuse `kSupportedFocusLanguageTags` for lookup* — rejected; `kSupportedFocusLanguageTags` is the catalog used for the user's **learning language** profile preference and is limited to 8 entries (no German, Italian, Portuguese, Russian). Reusing it would force a second expansion of the focus list to cover lookup needs, conflating two unrelated product concepts.
  - *Add a single `kSupportedAllLanguageTags` and derive others* — rejected; the existing native / focus / media lists have *different* semantics (mutually-exclusive, profile-backed, includes `und`) that don't compose cleanly into one list.

## 2. Lookup "first wave" tag set

- **Decision**: First-wave lookup language set is the union of the existing focus list (8 tags) plus German / Italian / Brazilian Portuguese / European Portuguese / Russian with regional variants, totalling **≥ 13** BCP-47 tags:
  - `en-US`, `en-GB`
  - `zh-CN`
  - `ja-JP`
  - `ko-KR`
  - `es-ES`, `es-MX`
  - `fr-FR`, `fr-CA`
  - `de-DE`
  - `it-IT`
  - `pt-BR`, `pt-PT`
  - `ru-RU`
- **Rationale**: Covers the top languages requested by Enjoy Player users as of 2026-07-08, matches the Azure pronunciation-assessment locale table where it overlaps (so future TTS / pronunciation work reuses the same set without re-mapping), and stays small enough that the in-sheet picker doesn't need a search box. Aligns with the spec's FR-001 / FR-002 / Assumptions.
- **Alternatives considered**:
  - *Match Azure Speech full locale table (24+ tags)* — rejected for v1; the user-reported need is "any target language", not "every pronunciation locale". Bundling pronunciation / TTS surface area into this change would expand the spec beyond FR-001 / FR-002.
  - *Match every ISO 639-1 primary subtag* — rejected; the picker would become unusable (≈ 180 entries) and most would not be supported by the worker.

## 3. Default target resolution when stored native ≠ expanded lookup list

- **Decision**: Extend `resolveLookupTarget` so that, when the stored native preference is **not** in the expanded lookup list, the sheet picks the closest supported target that is **not** equal to the source and **not** equal to the learning language. "Closest" matches the existing `canonicalLookupTag` algorithm (same primary subtag wins; otherwise first allowed non-learning entry). The expansion also feeds a new helper `resolveLookupSourceOverride(trackLanguage)` that **only** normalizes within the lookup set (so an `und` source still falls back to learning, as today).
- **Rationale**: Preserves the existing `coerceNativeIfEqualsLearning` behaviour so existing en-US / zh-CN users see no behaviour change. Adding the same primary-subtag fallback for unknown natives matches the pattern already used by `canonicalFocusLanguageTag` / `canonicalMediaLanguageTag`, so the catalog stays internally consistent.
- **Alternatives considered**:
  - *Force a re-migration prompt when stored native is unsupported* — rejected; over-engineering for a fallback target language, and the picker lets the user override on the spot anyway (FR-004).

## 4. Worker payload: keep `workerLanguageBase` only

- **Decision**: Continue to send `workerLanguageBase(sourceLanguage)` and `workerLanguageBase(targetLanguage)` for every section request. The full BCP-47 tag stays on `LookupRequest` / section params for UI display and cache keys, but never crosses the API boundary.
- **Rationale**: Already in place (`enjoy_translation_capability.dart`, `translation_api.dart` contract). The worker accepts `ko`, `ja`, etc. as base codes, so widening the lookup set requires no server changes. Aligns with FR-007 and ADR-0019.
- **Alternatives considered**:
  - *Send full BCP-47 to the worker and let it decide* — rejected; would change the existing web-app contract documented in ADR-0019 and could break caching on the server side.

## 5. Cache invalidation when source / target changes

- **Decision**: Treat the `(sourceLanguage, targetLanguage)` pair as part of every cache key. The existing `LookupTranslationParams`, `LookupContextualParams`, and `LookupDictionaryParams` already include both tags, so Riverpod's auto-family behaviour gives us per-pair caching "for free" — changing either tag produces a new params instance, which yields a new `Future` and a fresh fetch.
- **Rationale**: The current per-section `lookup_sheet_result_cache.dart` only memoizes dictionary + contextual results, and the key is the params struct. No code change is required beyond a guarantee that `setState` fires **before** any stale result can be observed. We add a single `LookupSheetResultCache.evictForPair(sourceLanguage, targetLanguage)` helper so a swap or explicit "Refresh" button can also drop cached entries for the prior pair — useful when the user wants to force a re-fetch without changing the pair. Aligns with FR-006, FR-010, and the swap edge case.
- **Alternatives considered**:
  - *Drop the entire cache on every pair change* — rejected; loses useful cross-selection reuse when the user opens the sheet on the same word twice with the same pair, and risks an extra round-trip on common flows.
  - *TTL-based cache with shared key* — rejected; introduces a time-based behaviour the rest of the app doesn't use, and the params-as-key approach already gives us the right granularity.

## 6. Picker UI: same widget, wider option list

- **Decision**: Reuse `LookupLanguagePickerRow` as-is, but switch its option source from `kSupportedNativeLanguageTags` to `kSupportedLookupLanguageTags`. The existing segmented control + chevron + swap button layout already handles arbitrary option counts (the picker bottom sheet scrolls). Add a single `sortLookupLanguages(tags, learningTag)` helper that orders the list with the user's learning language first, then alphabetical by primary subtag, then by region subtag.
- **Rationale**: Spec calls for no new dialog / no new tabbed UI (FR-003, QR-003). `LookupLanguagePickerRow` is built on `showLanguageChoiceSheet`, which already scrolls long lists and keeps the existing 44 px tap target, focus ring, and tooltip pattern. Sorting by learning-first matches the learner's mental model ("languages I care about most are at the top") and matches the existing pattern in `canonicalFocusLanguageTag` where the focus list is implicitly primary-subtag ordered.
- **Alternatives considered**:
  - *New search-as-you-type picker for 13+ entries* — rejected; 13 entries fit a standard scrollable list, and a search field would add a second widget surface to maintain for marginal benefit. Keep it as a follow-up if the list grows past ~20 entries (Arabic / Hindi / Vietnamese / Thai waves).
  - *Two-column grid in the picker* — rejected; existing choice sheet is single-column, change would touch all callers, and the new layout doesn't reduce scroll meaningfully at 13 entries.

## 7. Testing approach for catalog and resolver expansion

- **Decision**: Extend the existing `test/features/lookup/lookup_target_languages_test.dart` suite with cases for: (a) `canonicalLookupTag` for each new lookup tag, (b) `resolveLookupSourceOverride` for `und` / empty / unsupported / denylisted primaries, (c) `resolveLookupTarget` with a stored native that is **not** in the expanded list, (d) `sortLookupLanguages` ordering, (e) pair-as-key cache invalidation. Add a widget test for `LookupLanguagePickerRow` that mounts with two new tags and confirms both appear in the bottom-sheet option list. No new integration test — the existing `dictionary_lookup_sheet` flow is covered by widget tests when the params change; adding an integration test would only repeat that coverage at higher cost.
- **Rationale**: Constitution Principle II requires the narrowest automated tests that prove the changed contract. Catalog expansion is pure logic (unit), picker behavior is widget-rendering (widget), and the swap / cache / refresh logic is observable via the existing notifier families. No new test surface required.
- **Alternatives considered**:
  - *Golden-image picker test* — rejected; picker is scrollable, golden would only capture the first viewport and add CI cost without meaningful coverage.
  - *Integration test covering the full sheet* — rejected; the existing widget-test coverage at the section level is enough; integration tests are reserved for flows that span navigation + auth + persistence.

## 8. Documentation / ADR plan

- **Decision**: Add `docs/decisions/0042-multi-language-lookup-catalog.md` capturing: the decision to widen the lookup catalog (rationale, alternatives, risks), the explicit decoupling from `kSupportedNativeLanguageTags` / `kSupportedFocusLanguageTags`, and the no-persistence-per-sheet rule inherited from ADR-0019. Update `docs/features/dictionary-lookup.md` with the new "Languages" subsection (catalog name, ordering, default-target resolution, swap behaviour, cache key, error / worker-rejection handling). Update `AGENTS.md` to call out `kSupportedLookupLanguageTags` next to the existing catalog references.
- **Rationale**: Constitution Principle V requires an ADR for any architectural decision that is costly to reverse. Widening a catalog that ships to production is exactly that class of decision. Updating `docs/features/dictionary-lookup.md` keeps the feature doc in sync with behaviour, satisfying QR-005 / spec FR-005 traceability.
- **Alternatives considered**:
  - *Skip the ADR and document inline in the feature doc* — rejected; the project already relies on ADRs for catalog / scope decisions (ADR-0019 for the original lookup feature, ADR-0010 for cloud sync MVP), and an inline doc breaks that consistency.