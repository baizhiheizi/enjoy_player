# Feature Specification: Multi-language transcript lookup & translation

**Feature Branch**: `005-multilang-lookup`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "When I imported a kor video, on the kor transcript line, I select a kor word to lookup, it only provide english to Chinese. This is insane. We need to support multilanguage of lookup/translation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pick any target language for a Korean transcript lookup (Priority: P1)

A user has imported a Korean video and reads the Korean transcript alongside playback. They select a Korean word (e.g., on the active cue) and the bottom-sheet lookup opens. Today the target language is silently locked to either English or Chinese based on the user's "native" preference. The user wants to see the meaning of the word in **any language they pick**, including Japanese, Spanish, French, German, etc.

**Why this priority**: This is the bug reported verbatim — the picker is hard-capped at two native languages, which makes lookup unusable for any non-Chinese / non-English learner. Fixing this is the single most important behavior change.

**Independent Test**: Can be fully tested by importing a media file with a Korean transcript, selecting a Korean word on the active cue, opening the lookup sheet, opening the target picker, and verifying that at least eight target languages are offered (English, Chinese, Japanese, Korean, Spanish, French, German, Italian as a baseline) with the user's stored native preference preselected. Then refreshing the sheet and confirming that translation, contextual translation, and definition all return results in the chosen target language.

**Acceptance Scenarios**:

1. **Given** a media item whose active transcript track language is `ko-KR`, **When** the user selects a Korean word on the active cue and the lookup sheet opens, **Then** the source pill shows "한국어" (or the localized equivalent) and the target pill shows the user's stored native preference when that preference is in the expanded target list.
2. **Given** the lookup sheet is open with source = Korean, **When** the user taps the target pill and picks "日本語", **Then** the picker closes, the target pill now reads Japanese, the swap button becomes enabled, and the next translation / dictionary / contextual-translation request sent to the worker uses a `target` of `ja` (base code).
3. **Given** the user picks Japanese as the target, **When** the translation / contextual translation / dictionary sections are (re)fetched, **Then** all three sections render their output in Japanese, and no English or Chinese text is forced into the result payload.
4. **Given** the user has not signed in to Enjoy cloud, **When** the sheet is open and the user changes the target language, **Then** the auth-required callout is shown instead of an error row, and switching the target language does not consume credits.

---

### User Story 2 - Override the source language inside the sheet (Priority: P2)

A user has a media item whose primary transcript track language is "unknown" / `und` (no language metadata, mixed content, or `matchesLanguageBroad` ambiguity). Today the source silently falls back to the user's learning language. With multi-language lookup the user wants to **explicitly set** the source language inside the sheet so that, for example, they can pick "Japanese" as the source even when the track label is empty.

**Why this priority**: Complements the target-language picker. Without a source override, an `und` track can silently mistranslate content; with multi-language support we can let users correct that themselves without leaving the player.

**Independent Test**: Can be tested by opening the lookup sheet against a transcript whose track language is missing or `und`, tapping the source pill, picking each offered source, and verifying that the source pill updates, the swap button reflects the new pair, and the next section refresh requests use the new `source` base code. Also test that swapping source ↔ target swaps the language codes consistently (no off-by-one).

**Acceptance Scenarios**:

1. **Given** the active transcript track has no language metadata, **When** the lookup sheet opens, **Then** the source pill defaults to the user's learning language but is tappable.
2. **Given** the sheet is open with source = English (from learning fallback), **When** the user taps the source pill and picks "Français", **Then** the source pill updates, and the next translation / contextual-translation / dictionary refresh sends a `source` of `fr`.
3. **Given** the source and target are different, **When** the user taps the swap control, **Then** the source and target pills swap atomically, the swap button stays enabled (pair is still distinct), and any queued / stale requests are cancelled before the swap so no result from the prior pair leaks into the new pair.

---

### User Story 3 - Translate Korean → Chinese when learning English (Priority: P3)

A user is learning English, has set native = Chinese, and imports a Korean video. They want to read Korean → Chinese translations (their native language) without having to dig into settings. This story covers the default behavior when the picker has not been touched for the current sheet instance.

**Why this priority**: It preserves the current happy-path (native target, learning source fallback) so the expansion does not regress existing flows. Keeping it as a separate story means the P1 picker expansion does not block on default-behavior polish.

**Independent Test**: Can be tested by clearing the lookup sheet's in-memory override (re-opening a fresh sheet on a new selection), confirming that the target defaults to the user's stored native preference when that tag is part of the expanded list, and that the source defaults to the active transcript track language (or learning language fallback) — matching today's behavior for existing en-US / zh-CN users.

**Acceptance Scenarios**:

1. **Given** learning = English, native = Chinese, and an active transcript track with `ko-KR`, **When** the user opens a fresh lookup sheet (no prior override), **Then** source pill = "한국어", target pill = "中文", and the sheet calls the worker with `source = ko`, `target = zh`.
2. **Given** the same profile but the stored native preference is a tag that is **not** in the expanded target list, **When** the sheet opens, **Then** the target pill falls back to the closest supported target that is **not** equal to the learning language and is **not** equal to the active source.

---

### Edge Cases

- **Source = target** is impossible: the picker must always offer at least one allowed target that differs from the selected source, and the swap control must be disabled when only one choice remains.
- **Track with `und` + learning fallback same as user's only other supported native** (e.g., learning = `en-US`, native = `zh-CN`): the picker can still offer both English and Chinese; this case is covered by the existing `coerceNativeIfEqualsLearning` logic but must continue to work after the catalog is expanded.
- **Worker rejects an unsupported target** (e.g., a translation pair the Enjoy cloud cannot fulfil): the section should show a localized error row with a **Retry** action and a brief explanation that the pair is not supported — no silent fallback to English / Chinese.
- **Offline / signed out**: behavior is unchanged — auth-required callout is shown for all target languages, not just the existing two.
- **Cached results from a previous lookup**: when the user changes source or target inside the sheet, cached translations / contextual-translation / dictionary results from the prior pair must be discarded before the new request is fired so the user never sees the wrong language result attached to the wrong pair.
- **Large transcript libraries / long-running session**: changing the source/target must not stall the main isolate — section refreshes should remain debounced and show the existing shimmer skeletons.
- **Platform chrome**: the source / target picker must remain usable on Android, iOS, macOS, and Windows input patterns (touch, mouse, keyboard) and keep the existing 44 px tap target, focus ring, and tooltip affordances.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose an **expanded** lookup target language set that includes at minimum: `en-US`, `en-GB`, `zh-CN`, `ja-JP`, `ko-KR`, `es-ES`, `es-MX`, `fr-FR`, `fr-CA`, `de-DE`, `it-IT`, `pt-BR`, `pt-PT`, `ru-RU`. Each entry MUST have a localized human-readable label (English and Chinese localized strings added to ARB).
- **FR-002**: System MUST expose an **expanded** lookup source language set that mirrors the target list (minus invalid / `und` / `mul` / `mis` / `zxx`) so that the user can override the source inside the sheet even when the active transcript track is `und`.
- **FR-003**: The lookup sheet's source / target picker row MUST show every supported language, sorted by the user's learning language first, then alphabetical by primary subtag, with the active selection highlighted. The picker MUST never silently exclude a supported language because the user's stored native preference is not in that language.
- **FR-004**: When the sheet opens for the first time (no in-memory override for the current session), the target MUST default to the user's stored native preference if it is in the expanded target list, otherwise to the closest supported target that is **not** equal to the source and **not** equal to the learning language.
- **FR-005**: When the sheet opens, the source MUST default to the active transcript track language when it is a valid supported language, otherwise to the user's learning language (current `resolveLookupSource` behavior preserved).
- **FR-006**: The user MUST be able to swap source ↔ target with the existing segmented control swap button. After a swap, all in-flight section requests MUST be cancelled and any cached results from the prior pair MUST be discarded before the new pair's requests are fired.
- **FR-007**: The worker request payload (translation, dictionary, contextual translation) MUST send the **stripped base** language code (per existing `workerLanguageBase`) for both `source` and `target`, regardless of which language the user picks in the sheet. The full BCP-47 tag MAY be retained on the `LookupRequest` for UI display but MUST NOT be sent to the worker.
- **FR-008**: The lookup sheet MUST show a localized error row when the worker rejects the chosen source / target pair, including a localized "Retry" affordance. It MUST NOT silently fall back to `en-US` / `zh-CN` when the user explicitly chose another pair.
- **FR-009**: Existing user profile preferences (`nativeLanguage`, `learningLanguage`) MUST continue to be restricted to the existing two `kSupportedNativeLanguageTags` (`en-US`, `zh-CN`) and `kSupportedFocusLanguageTags` lists respectively. The expanded lookup target / source set MUST be a **separate** catalog (e.g., `kSupportedLookupLanguageTags`) so profile / settings UI does not regress.
- **FR-010**: Section result cache keys MUST include both the source and target tags so that changing either language invalidates the cached translation / dictionary / contextual translation results for the prior pair.
- **FR-011**: ARB localization files MUST add the human-readable labels for each newly supported lookup language under `appLocalizations` (both `app_en.arb` and `app_zh.arb`); existing lookup strings (`lookupSourceLanguage`, `lookupTargetLanguage`, `lookupSwapLanguages`, `lookupPickSourceTitle`, `lookupPickTargetTitle`, `lookupCloudRequiresSignIn`, `lookupErrorRetry`) MUST remain unchanged.
- **FR-012**: Auth-required callout MUST be shown for **all** supported target / source languages, not just `en-US` / `zh-CN`, when the user is signed out.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture; all language catalog additions MUST live under `lib/core/application/app_language_catalog.dart` (no scattered constants in widget files), per ADR-0018 and `docs/conventions.md`.
- **QR-002**: Behavior changes MUST have automated tests covering at minimum: catalog expansion, target / source resolution (valid / invalid / `und` / `native == learning` / `native not in expanded list`), worker payload base-code stripping, swap behavior, and section-cache invalidation on pair change. Existing tests in `test/features/lookup/lookup_target_languages_test.dart` MUST be updated / extended rather than duplicated.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns (`EnjoyTappableSurface`, `Haptics`, `Tooltip`, ARB). The picker must keep the existing segmented control row layout (no new dialogs, no new tabbed UI).
- **QR-004**: User-visible flows MUST define measurable performance expectations: opening the picker, picking a target, refreshing the three sections, and rendering the first section response MUST each complete in under 300 ms on the slowest supported platform (Windows desktop, cold cache) for a sheet with a Korean source and any expanded target. No picker interaction may stall playback, scroll, or transport-bar updates.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/dictionary-lookup.md`, and a new ADR MUST be added under `docs/decisions/` covering the catalog-expansion decision (rationale, alternatives, risks) before implementation begins.

### Key Entities *(include if feature involves data)*

- **LookupLanguageTag**: A BCP-47 tag with primary subtag (e.g., `ko-KR`). Has a human-readable label (per locale), a "is supported for lookup" flag, and a worker base code (e.g., `ko`). Used by the source / target picker.
- **LookupLanguagePair**: A `(source, target)` ordered pair of `LookupLanguageTag` values, used as the cache key for section results and as the unit of "swap". Cached section results are scoped to a single pair.
- **LookupRequest (existing)**: Adds the expanded `sourceLanguage` / `targetLanguage` semantics — same fields, expanded allowed-value domain. No shape change required; semantics expansion only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a user opens the lookup sheet against any non-`und` transcript track (Korean, Japanese, Spanish, French, German, Italian, Portuguese, Russian, English, Chinese — first wave), the target picker offers at least the full expanded target list (≥ 13 entries) within 100 ms of the sheet opening on Windows desktop with a cold cache.
- **SC-002**: For a Korean transcript lookup, after the user picks any target language from the expanded list (e.g., Japanese, Spanish, French), the translation section returns a non-empty result whose content language matches the chosen target within 2.5 s p95 on a 50 Mbps connection, with no English / Chinese fallback injected.
- **SC-003**: Dictionary and contextual-translation sections, when expanded after a target change, return results whose content language matches the chosen target within 2.5 s p95 under the same conditions; no error row is shown solely because the user picked a non-English / non-Chinese target.
- **SC-004**: When the user swaps source ↔ target inside the sheet, the three sections discard stale results from the prior pair and the first section refresh of the new pair starts within 50 ms of the swap, with no flickering of the prior pair's content visible above the shimmer skeletons.
- **SC-005**: 100% of existing en-US / zh-CN users keep their current default behavior (native preference preselected, learning fallback for `und`) after the catalog is expanded — measured by existing `lookup_target_languages_test.dart` suite passing unchanged except for catalog-driven expected-value updates.
- **SC-006**: Zero regressions in playback, transcript scrolling, or transport-bar responsiveness while the lookup sheet is open across the expanded language set — measured by reusing the existing performance evidence pattern from `docs/conventions.md` § Sliver performance.

## Assumptions

- The Enjoy worker `POST /translations`, `POST /dictionary/query`, and `POST /chat/completions` already accept arbitrary `source` / `target` language codes via `workerLanguageBase`. The current limitation is purely client-side (the picker UI hard-caps the choice to `en-US` / `zh-CN`), so the worker contract does not need changes.
- The expanded lookup target / source set is **separate** from the user's stored `nativeLanguage` profile preference. We assume users will continue to set their native language to one of `en-US` / `zh-CN` for UI / profile purposes; the lookup picker simply gives them a wider choice per-transcript-line lookup.
- "First wave" target set (English, Chinese, Japanese, Korean, Spanish, French, German, Italian, Portuguese, Russian with US / GB, CN, JP, KR, ES, MX, FR, CA, DE, IT, BR, PT, RU regional variants) covers the top languages requested by Enjoy Player users as of 2026-07-08. Additional languages (Arabic, Hindi, Vietnamese, Thai, etc.) may follow in a follow-up spec but are explicitly out of scope for this change.
- Dictionary entries for less-common language pairs (e.g., Korean → Russian) may be sparse in the worker; in that case the dictionary section shows the standard error row rather than a synthetic fallback. This is a known limitation, not a bug.
- The user's stored native preference continues to act as the **default** target when opening a fresh sheet, even though the user can override per sheet. We do **not** persist per-sheet overrides across app restarts (matches existing ADR-0019 "not persisted" decision).
- Display locales for the app UI remain English (`en-US`) and Simplified Chinese (`zh-CN`); the expanded language list affects **lookup source/target** only, not the localized UI strings of the app.