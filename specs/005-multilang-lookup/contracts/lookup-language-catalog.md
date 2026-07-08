# UI Contract: Lookup Language Catalog

**Implements**: FR-001, FR-002, FR-009, FR-011, and the catalog-separation rationale from [research.md §1](../research.md#1-catalog-separation-lookup-languages-vs-profile--focus--media-languages).

## Contract

1. **New constant** `kSupportedLookupLanguageTags: List<String>` lives in `lib/core/application/app_language_catalog.dart` next to the existing `kSupportedNativeLanguageTags` and `kSupportedFocusLanguageTags`. It MUST be the **only** source of truth for the lookup sheet's source / target options.
2. **First-wave tag set** (≥ 13 entries): `en-US`, `en-GB`, `zh-CN`, `ja-JP`, `ko-KR`, `es-ES`, `es-MX`, `fr-FR`, `fr-CA`, `de-DE`, `it-IT`, `pt-BR`, `pt-PT`, `ru-RU`. Each entry MUST round-trip through `normalizeBcp47Tag` to its canonical form.
3. **Per-tag labels** extend the existing `kLookupLanguageLabels: Map<String, String>` map. Each entry has both English and Simplified-Chinese translations; English comes from the existing `app_en.arb` and Chinese from the existing `app_zh.arb`. Pre-existing entries (`en-US`, `zh-CN`) are preserved unchanged.
4. **Decoupling**: `kSupportedLookupLanguageTags` is **independent** of `kSupportedNativeLanguageTags` and `kSupportedFocusLanguageTags`. Widening the lookup set MUST NOT change the Profile / Settings pickers for "native language" or "learning language" — those continue to iterate their respective narrower catalogs.
5. **Validation**: every entry in `kSupportedLookupLanguageTags` MUST (a) have a matching key in `kLookupLanguageLabels`, (b) NOT be in `kInvalidLanguageTags`, (c) round-trip through `workerLanguageBase` to its expected primary subtag. These invariants are asserted by `test/core/application/lookup_catalog_test.dart`.
6. **Failure mode**: if a non-supported tag slips in (defensive coding), the catalog assertion at app start MUST log via `logNamed('AppLanguageCatalog').warning(...)` and exclude it from option lists rather than crashing.

## Out of scope

- No additional languages beyond the first wave (Arabic / Hindi / Vietnamese / Thai / etc.) — explicitly deferred per the spec's Assumptions section.
- No automatic locale detection of the active transcript beyond the existing `canonicalMediaLanguageTag` flow — the picker is the explicit user override path.
- No per-language variant of the lookup UI itself (e.g., RTL); the picker bottom sheet inherits the existing app locale (en / zh-CN).

## Change surface

| File | Change |
|---|---|
| `lib/core/application/app_language_catalog.dart` | +`kSupportedLookupLanguageTags`, +`kLookupLanguageLabels` entries for the 12 new tags, +`sortLookupLanguages` helper, +`resolveLookupSourceOverride` (in the lookup sub-folder), and extended `resolveLookupTarget` fallback. |
| `test/core/application/lookup_catalog_test.dart` (new) | Catalog invariants. |
| `test/features/lookup/lookup_target_languages_test.dart` (extended) | New resolver cases. |
| `lib/l10n/app_en.arb` / `app_zh.arb` | Per-language labels (new keys, no removal). |