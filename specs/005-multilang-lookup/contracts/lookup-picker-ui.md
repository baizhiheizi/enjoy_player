# UI Contract: Lookup Language Picker Row

**Implements**: FR-003, FR-004, FR-005, FR-006, FR-008, FR-012, and the swap + cache-invalidation edge cases from [spec.md](../spec.md#edge-cases).

## Contract

1. **Option source**: `LookupLanguagePickerRow` consumes `kSupportedLookupLanguageTags` (not `kSupportedNativeLanguageTags`) for both the source and target option lists. Option lists are pre-sorted via `sortLookupLanguages(tags, learningTag: learn)` so the user's learning language is first, then alphabetical by primary subtag, then by region.
2. **Source pill**: when tapped, opens the existing `showLanguageChoiceSheet` with the **full** `kSupportedLookupLanguageTags` list. Selection updates `_DictionaryLookupSheetState._sourceLanguage` and re-fires all three section providers via `setState`. Empty / whitespace / invalid overrides fall back to `resolveLookupSource(activeTrack.language, learningTag)` per FR-005.
3. **Target pill**: when tapped, opens the same bottom sheet with the `kSupportedLookupLanguageTags` list filtered to entries that are **not** equal to the current source. Selection updates `_DictionaryLookupSheetState._targetLanguage`. Per FR-004, the default target on first open is the user's stored native preference if it is in the lookup list, otherwise the closest supported target that is not equal to source and not equal to learning.
4. **Swap control**: tapping swaps source ↔ target atomically. The button is disabled when source == target (no possible swap). After a swap, the sheet calls `LookupSheetResultCache.evictForPair(prevSource, prevTarget)` so stale results from the prior pair cannot be observed against the new pair's loading skeletons.
5. **Refresh**: the existing `LookupRefreshIconButton` retains its current per-section behaviour. On swap or manual refresh of an expanded section, the cache is evicted for the pair and a fresh fetch starts within 50 ms of the user action (SC-004).
6. **Auth-required callout**: when the user is signed out, every section shows `AuthRequiredCallout` for **all** supported lookup languages — not just the original two natives. The surface enum (`AuthRequiredSurface.lookupTranslation`, `.lookupDictionary`, `.lookupContextualTranslation`) is unchanged; the callout already localizes per FR-012.
7. **Worker rejection**: if the worker rejects the chosen source / target pair (e.g., unsupported regional variant), the section renders `LookupErrorRow` with the localized error message and the existing **Retry** affordance (`lookupErrorRetry`). No silent fallback to `en-US` / `zh-CN` (FR-008).
8. **Persistence**: per-sheet overrides are **not** persisted across app restarts — matches ADR-0019 "not persisted" decision. The lookup sheet re-opens with the default target = user's stored native preference.

## Layout invariants

- The picker keeps the existing segmented control row layout (`EnjoyTappableSurface` segments with chevrons, centered swap control, 44 px tap targets, vertical divider at 28% alpha).
- `Tooltip` on the swap control (`lookupSwapLanguages`) is unchanged.
- The existing 28%-alpha vertical divider between segments is unchanged.
- No new dialogs / tabs / search field / grid — option lists stay as scrollable single-column lists inside `showLanguageChoiceSheet`.

## Change surface

| File | Change |
|---|---|
| `lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart` | Switch option source from `kSupportedNativeLanguageTags` to `kSupportedLookupLanguageTags`; pass `learningTag` to `sortLookupLanguages`; adjust the post-pick "auto-switch target when source picks the current target" branch to use the lookup list. |
| `lib/features/lookup/presentation/dictionary_lookup_sheet.dart` | On `_sourceLanguage` / `_targetLanguage` change and on swap, call `LookupSheetResultCache.evictForPair(prevSource, prevTarget)` before `setState` so stale results can't render above the shimmer skeletons. |
| `lib/features/lookup/application/lookup_sheet_result_cache.dart` | +`evictForPair({sourceLanguage, targetLanguage})` helper. |
| `test/features/lookup/lookup_language_picker_row_test.dart` (new) | Picker renders the full option list; swap control toggles; source/target independence; `evictForPair` integration. |

## Out of scope

- No fuzzy search / typeahead in the picker — the first-wave list (≥ 13 entries) fits a standard scrollable list; deferred until the list grows past ~20 entries (Arabic / Hindi / Vietnamese / Thai waves).
- No saving of the user's "last picked target" across app restarts — explicitly rejected per ADR-0019 and the spec's Assumptions.
- No bulk lookups (multi-word selections) — existing 1–100 character selection range is preserved.