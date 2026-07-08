# Phase 1 Data Model: Multi-language transcript lookup & translation

No Drift schema changes. All entities below are pure-Dart domain types or in-memory application state scoped to the lookup sheet's lifetime, backed by existing code paths or new compile-time constants in `lib/core/application/app_language_catalog.dart`.

## `LookupLanguageTag` (catalog entry, pure Dart)

Compile-time constant — one BCP-47 tag with a human-readable label per locale. Lives in `lib/core/application/app_language_catalog.dart` as two new sibling maps: `kSupportedLookupLanguageTags: List<String>` (the ordered tag list) and `kLookupLanguageLabels: Map<String, String>` (per-tag UI label). The existing `kLookupLanguageLabels` map is **extended** with new entries; the existing `en-US` / `zh-CN` entries are preserved.

| Tag | Primary | Region | Label (en) | Label (zh) | First-wave inclusion |
|---|---|---|---|---|---|
| `en-US` | `en` | `US` | `English` | `英语` | ✅ |
| `en-GB` | `en` | `GB` | `English (UK)` | `英语（英国）` | ✅ |
| `zh-CN` | `zh` | `CN` | `中文` | `中文` | ✅ |
| `ja-JP` | `ja` | `JP` | `日本語` | `日语` | ✅ |
| `ko-KR` | `ko` | `KR` | `한국어` | `韩语` | ✅ |
| `es-ES` | `es` | `ES` | `Español (España)` | `西班牙语（西班牙）` | ✅ |
| `es-MX` | `es` | `MX` | `Español (México)` | `西班牙语（墨西哥）` | ✅ |
| `fr-FR` | `fr` | `FR` | `Français (France)` | `法语（法国）` | ✅ |
| `fr-CA` | `fr` | `CA` | `Français (Canada)` | `法语（加拿大）` | ✅ |
| `de-DE` | `de` | `DE` | `Deutsch` | `德语` | ✅ |
| `it-IT` | `it` | `IT` | `Italiano` | `意大利语` | ✅ |
| `pt-BR` | `pt` | `BR` | `Português (Brasil)` | `葡萄牙语（巴西）` | ✅ |
| `pt-PT` | `pt` | `PT` | `Português (Portugal)` | `葡萄牙语（葡萄牙）` | ✅ |
| `ru-RU` | `ru` | `RU` | `Русский` | `俄语` | ✅ |

**Validation rules**:
- Every entry in `kSupportedLookupLanguageTags` MUST have a matching entry in `kLookupLanguageLabels` (asserted by `test/core/application/lookup_catalog_test.dart` new file).
- Every entry MUST round-trip through `normalizeBcp47Tag` / `workerLanguageBase` to the expected primary subtag (asserted in `lookup_target_languages_test.dart` extension).
- `kSupportedLookupLanguageTags` MUST NOT contain `und`, `mul`, `mis`, `zxx`, empty string, or any tag in `kInvalidLanguageTags` (asserted in same test).

**State transitions**: None — compile-time constants.

**Worker payload**: For each tag, `workerLanguageBase(tag)` returns the primary subtag (e.g. `ko-KR` → `ko`). The full BCP-47 tag is retained on `LookupRequest` and section params for UI display and cache keys, but never sent to the worker (FR-007).

## `LookupLanguagePair` (derived, not stored)

An **ordered** pair `(sourceLanguage, targetLanguage)` of `LookupLanguageTag` values. Used as:
- The **cache key** for `LookupSheetResultCache` (per [research.md](./research.md) §5): the pair is part of every section params struct, so per-pair caching is automatic.
- The **identity** of a swap action: the swap control in `LookupLanguagePickerRow` exchanges source ↔ target atomically.

Not a separate domain type — implemented via the existing `LookupTranslationParams`, `LookupContextualParams`, and `LookupDictionaryParams` (already include `sourceLanguage` + `targetLanguage`) and via the new `LookupSheetResultCache.evictForPair(source, target)` helper.

## `LookupSourceOverride` (application state, ephemeral)

Per-sheet override for the source language when the user changes it inside the picker.

| Field | Type | Notes |
|---|---|---|
| `sourceLanguage` | `String?` | Null = no override; use `resolveLookupSource(activeTrackLanguage, learningTag)` from FR-005. Non-null = user-picked source. |

Backed by `_DictionaryLookupSheetState._sourceLanguage` (already exists as in-sheet state). Ephemeral — resets when the sheet is reopened. Per-spec FR-006, no persistence across app restarts (matches ADR-0019 "not persisted" decision).

## `LookupTargetOverride` (application state, ephemeral)

Per-sheet override for the target language when the user changes it inside the picker.

| Field | Type | Notes |
|---|---|---|
| `targetLanguage` | `String?` | Null = no override; use `resolveLookupTarget(storedNative, learningTag)` from FR-004. Non-null = user-picked target. |

Backed by `_DictionaryLookupSheetState._targetLanguage` (already exists). Ephemeral — same lifetime as `LookupSourceOverride`.

## `LookupSheetResultCache` (extended, application state)

Existing in-memory cache, extended with a pair-scoped evict helper. Lives in `lib/features/lookup/application/lookup_sheet_result_cache.dart`.

| Field | Type | Notes |
|---|---|---|
| `_contextual` | `Map<LookupContextualParams, ContextualTranslationResult>` | Unchanged. |
| `_dictionary` | `Map<LookupDictionaryParams, DictionaryResult>` | Unchanged. |

**New method**:
```dart
void evictForPair({required String sourceLanguage, required String targetLanguage});
```
Removes every entry whose params struct's `sourceLanguage == sourceLanguage && targetLanguage == targetLanguage`. Called from the sheet on swap (so stale pair results are not observed against the new pair's loading skeletons) and from the existing refresh icon button path.

`peekContextual` / `peekDictionary` / `rememberContextual` / `rememberDictionary` / `evictContextual` / `evictDictionary` remain unchanged.

## `resolveLookupSourceOverride` (new, pure logic)

New helper in `lib/features/lookup/application/lookup_target_languages.dart`. Resolves the source language when the **user overrides** it inside the picker, distinct from the existing `resolveLookupSource` which resolves from the active transcript track.

```dart
String resolveLookupSourceOverride(String? override);
```

**Validation rules**:
- Empty / whitespace / `und` / `mul` / `mis` / `zxx` → `null` (caller falls back to `resolveLookupSource`).
- Otherwise returns `normalizeBcp47Tag(override)`.

The picker passes the user's choice through `resolveLookupSourceOverride`; if it returns `null`, the sheet falls back to the original source resolution. This keeps the existing FR-005 default behaviour for users who don't touch the source pill.

## `resolveLookupTarget` (extended, pure logic)

Existing helper in `lib/features/lookup/application/lookup_target_languages.dart`. Extended per [research.md](./research.md) §3 so a stored native that is **not** in `kSupportedLookupLanguageTags` falls back to the closest supported tag whose primary subtag matches, or to the first entry in `kSupportedLookupLanguageTags` that is **not** equal to source and **not** equal to learning.

```dart
String resolveLookupTarget(String? nativeLanguage, {required String learningTag});
```

**Validation rules** (extended):
- If `nativeLanguage` canonicalizes to a tag in `kSupportedLookupLanguageTags` AND is not equal to `learningTag` (per existing `coerceNativeIfEqualsLearning`), return it.
- Otherwise, look up the **primary subtag** of `nativeLanguage` in `kSupportedLookupLanguageTags` (e.g. stored native = `de-AT` → primary `de` → first `de-*` in the lookup list = `de-DE`).
- Otherwise, return the first entry in `kSupportedLookupLanguageTags` that is not equal to source and not equal to learning.
- Source-equal target is impossible: the picker enforces this and `resolveLookupTarget` returns the **first non-equal entry** as a last resort.

## `sortLookupLanguages` (new, pure logic)

```dart
List<String> sortLookupLanguages(List<String> tags, {required String learningTag});
```

Returns the input tags sorted with the user's learning language first (primary-subtag match), then alphabetical by primary subtag, then by region subtag. Used by `LookupLanguagePickerRow` to pre-order the bottom-sheet option list so the user sees the languages they care about most at the top.

Validation rules:
- Input list is expected to be a subset of `kSupportedLookupLanguageTags`; output is a new `List<String>` (does not mutate the input).
- Stable for ties (preserves `kSupportedLookupLanguageTags` order within an alphabetical bucket).

## Relationships

```text
kSupportedLookupLanguageTags (compile-time constant list, N entries)
   └── kLookupLanguageLabels (Map<String, String>) — one label per entry, both en + zh localized
   └── sortLookupLanguages(tags, learningTag) → pre-sorted option list for the picker

LookupRequest (existing)
   ├── sourceLanguage (full BCP-47 tag, retained for UI / cache)
   ├── targetLanguage (full BCP-47 tag, retained for UI / cache)
   └── selectedText / contextualContext

LookupTranslationParams / LookupContextualParams / LookupDictionaryParams (existing)
   ├── sourceLanguage + targetLanguage → form the (source, target) pair that drives the cache key
   └── workerLanguageBase(sourceLanguage / targetLanguage) is what actually crosses the API boundary

LookupSheetResultCache (extended)
   ├── rememberDictionary / rememberContextual — unchanged
   ├── evictDictionary / evictContextual — unchanged (single-entry)
   └── evictForPair(source, target) — NEW; called on swap + manual refresh

DictionaryLookupSheet (existing StatefulWidget)
   ├── _sourceLanguage (LookupSourceOverride; ephemeral)
   ├── _targetLanguage (LookupTargetOverride; ephemeral)
   └── on swap / source / target change → setState + evictForPair(prev source, prev target)
```

## Validation summary

| Test | Asserts |
|---|---|
| `test/core/application/lookup_catalog_test.dart` (new) | `kSupportedLookupLanguageTags` and `kLookupLanguageLabels` agree (same key set); every tag round-trips through `normalizeBcp47Tag`; no entry is in `kInvalidLanguageTags`. |
| `test/features/lookup/lookup_target_languages_test.dart` (extended) | `canonicalLookupTag` for each new lookup tag; `resolveLookupSourceOverride` rejects `und` / empty / `mul`; `resolveLookupTarget` falls back when stored native is `de-AT` (not in list), `fr-CH` (not in list), and `en-XX` (in list); `sortLookupLanguages` ordering. |
| `test/features/lookup/lookup_language_picker_row_test.dart` (new) | Picker renders the full option list; swap control toggles; per-source / target independence. |
| `test/features/lookup/lookup_sheet_result_cache_test.dart` (new) | `evictForPair` removes only matching entries; leaves non-matching entries intact. |