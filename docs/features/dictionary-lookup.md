# Feature: Dictionary lookup (transcript)

## Summary

While playback is open, the user can **select 1–100 characters** on the **active** transcript cue or on any cue inside the **echo window**. A **bottom sheet** opens automatically (debounced) with:

1. **Translation** — `POST /translations` via `translationServiceProvider`.
2. **Definition (dictionary)** — `POST /dictionary/query` via `dictionaryServiceProvider` (word = selected text only). In the sheet UI this section is labeled **Definition** / **释义** (`lookupSectionDictionary`).
3. **Contextual translation** — LLM markdown via `POST /chat/completions` through `contextualTranslationServiceProvider` (system prompts aligned with web `contextual-translation`); includes optional **surrounding transcript context** from `buildVocabularyContext`.

Sections appear in the sheet in that order: translation, then definition/dictionary, then contextual translation.

## Languages

- **Default source** comes from the **active primary transcript** track’s `language` field (not the media row / `PlaybackSession.language`, which may be `und`).
- **Validation** — `canonicalLookupTag` maps supported tags to `en-US` / `zh-CN`; `und`, empty, and other unsupported values fall back to the **learning language** for source; target uses the stored native tag with the same canonicalization plus **never-native-equals-learning** coercion.
- **In-sheet override** — Source / target can be changed per lookup via the picker row (`LookupLanguagePickerRow`); choices are **not** persisted (web parity).
- **Worker payloads** — Translation, dictionary, and contextual system prompts use **stripped base** language codes (`workerLanguageBase`) so the backend never receives regioned `und` or full BCP-47 where the worker expects `en` / `zh`.

## UX rules

- **Tap-to-seek** is **disabled** on selectable rows (active + echo cues); other rows behave as before.
- **Selection toolbar** is suppressed on transcript selections; the sheet is the primary affordance.
- **Signed out** — Translation, dictionary, and contextual sections **do not** call the Worker while the user is not `AuthSignedIn`. Each section shows a compact **Account required** callout with a **Sign in** button (`AuthRequiredCallout`) that navigates to `/sign-in?from=…`. After **AuthFailure** (e.g. expired session), the same callout is shown instead of a retry-only error row.
- **Translation** section is expanded on first open and fetches immediately when signed in. **Definition (dictionary)** and **contextual translation** start **collapsed** — expand once to fetch when signed in (saves credits vs eager triple fetch).
- **Sheet chrome** — Header, selected term (hero panel with gradient + border), and language row are grouped at the top; scrollable sections use elevated cards (`LookupExpansionCard`) with a nested content well. **Copy** uses a tonal icon button and shows a short **success notice** (`AppNotice` / `lookupCopySuccess`).
- **Language row** — Single segmented control with chevrons on source/target and a centered swap control.

## Code map

| Area | Path |
|------|------|
| Open sheet from transcript | [`lib/features/lookup/application/transcript_lookup_open.dart`](../../lib/features/lookup/application/transcript_lookup_open.dart) |
| Source/target resolution | [`lib/features/lookup/application/lookup_target_languages.dart`](../../lib/features/lookup/application/lookup_target_languages.dart) |
| Language catalog + worker base | [`lib/core/application/app_language_catalog.dart`](../../lib/core/application/app_language_catalog.dart) |
| Context builder | [`lib/features/lookup/application/vocabulary_context_builder.dart`](../../lib/features/lookup/application/vocabulary_context_builder.dart) |
| Sheet UI | [`lib/features/lookup/presentation/dictionary_lookup_sheet.dart`](../../lib/features/lookup/presentation/dictionary_lookup_sheet.dart) |
| Language picker row | [`lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart`](../../lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart) |
| Section async providers | [`lib/features/lookup/application/lookup_section_providers.dart`](../../lib/features/lookup/application/lookup_section_providers.dart) |
| Auth-required callout (sign-in CTA) | [`lib/features/auth/presentation/widgets/auth_required_callout.dart`](../../lib/features/auth/presentation/widgets/auth_required_callout.dart) |
| Selectable cue row | [`lib/features/transcript/presentation/transcript_line_tile.dart`](../../lib/features/transcript/presentation/transcript_line_tile.dart) |

## Related

- ADR: [`docs/decisions/0019-transcript-dictionary-lookup.md`](../decisions/0019-transcript-dictionary-lookup.md)
- AI routes: [`docs/features/ai.md`](ai.md)
- Transcript panel: [`docs/features/transcript.md`](transcript.md)
