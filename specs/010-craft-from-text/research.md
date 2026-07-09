# Research: Craft from Text (AI-generated audio materials)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> No `NEEDS CLARIFICATION` markers remain in the spec or plan. This document captures the technical research that informed the plan: existing capability wiring, the Enjoy AI TTS gap, TTS BYOK readiness, dedupe conventions, library badge patterns, and provider routing.

## Decisions

### D1. Enjoy AI TTS path is implemented via Azure Speech SDK + worker-issued token (parallel to Enjoy assessment)

- **Decision**: `EnjoyTtsCapability.synthesize` uses the same `AzureSpeech.instance.synthesize` call as `EnjoyAssessmentCapability` does for assessment, fetching a short-lived token via `AzureTokenCache.getToken(purpose: 'tts', durationSeconds: ...)`.
- **Rationale**: The Azure Speech SDK is already integrated via the in-tree package `packages/azure_speech` and the assessment flow already demonstrates the worker-token + native SDK pattern end-to-end (see `lib/features/ai/data/enjoy/enjoy_assessment_capability.dart` and `lib/data/api/services/ai/azure_token_cache.dart`). The BYOK Azure TTS path (`byok_tts_azure_capability.dart`) is already implemented against the same SDK surface, so this reuses one of two paths depending on which modality config is active.
- **Alternatives considered**:
  - Call Azure Speech REST directly from Flutter — rejected: avoids the worker credit accounting and breaks provider symmetry.
  - Build a dedicated Enjoy TTS worker endpoint — rejected: the existing `AzureTokenCache` pattern is already proven for the assessment modality; reusing it gives the same reliability and cost-attribution guarantees.
  - Wait for a worker-side TTS route — rejected: the spec FR-009 requires Craft to ship now; the Azure Speech SDK + worker token approach is the established way to ship a TTS capability in this app.

### D2. TTS BYOK card stays in `ai_providers_screen.dart`; copy is updated from "P3" placeholder to first-class

- **Decision**: The existing `ModalityProviderCard` already renders TTS as one of the four modality cards (LLM, ASR, TTS, assessment). The capability layer for both BYOK backends (OpenAI-compatible, Azure Speech) is implemented and tested (`byok_tts_openai_capability.dart`, `byok_tts_azure_capability.dart`). This change does NOT introduce a new TTS settings card — it removes the "P3 / Coming Soon" feel by (a) updating the localized `settingsAiProvidersModalityTts` hint copy to remove any "stub" phrasing, (b) ensuring the TTS card sits in the same order ASR / LLM / TTS / assessment appear in other surfaces, and (c) updating `docs/features/ai.md` to describe it as first-class.
- **Rationale**: Re-using the existing card avoids layout drift and keeps the four-card surface visually consistent. Spec 003 already listed TTS BYOK as P3; promoting it is purely a copy + doc change plus a "first-class" label in `quickstart.md` and `ai.md`.
- **Alternatives considered**:
  - Add a separate TTS-only settings route — rejected: breaks the four-card surface pattern and creates a parallel path for users.
  - Embed TTS settings inside the Craft sheet itself — rejected: provider configuration is a settings concern, not an import-flow concern.

### D3. Provider value `craft` (no migration needed)

- **Decision**: Craft-generated media rows store `Audios.provider = 'craft'`. The `source` column stores `'craft-translate'` (Translate then speak) or `'craft-direct'` (Speak directly).
- **Rationale**: `Audios.provider` is a free-form `text().withDefault(const Constant('user'))()` column — no schema migration. The library grid already keys provider-specific UI off this column (e.g. the YouTube badge uses `provider == 'youtube'`). Adding a new value is the same change shape as adding the YouTube provider in spec 0015.
- **Alternatives considered**:
  - Reuse `provider = 'user'` with a non-null `source` field — rejected: loses the explicit "this is Craft" signal that the library badge relies on, and breaks the symmetry with how YouTube / local are distinguished.
  - New boolean column `is_crafted` — rejected: adds a column for a single feature and breaks the established provider-based UI contract.

### D4. Dedupe uses content hash over `(mode, learningLanguage, canonicalized text)`

- **Decision**: `MediaLibraryRepository.importCraftedFromText(...)` computes `SHA-256(mode + '|' + learningLanguage + '|' + canonicalText)` (with NFC-normalized, whitespace-collapsed text) and looks up an existing `AudioRow` by `md5`. If present, returns the existing id (consistent with `importYoutubeVideo`'s dedupe pattern).
- **Rationale**: Pasting the same text twice should not duplicate the audio. The hash is deterministic and stable across syncs, so cloud sync can dedupe the same Craft on another device. NFC normalization avoids trivial duplicate pastes with different Unicode representations.
- **Alternatives considered**:
  - Dedupe by raw text string — rejected: same text in different representations should dedupe.
  - Dedupe by audio bytes hash — rejected: requires synthesizing twice before we know it is a duplicate (wasted API call + cost).

### D5. Length cap of 5 000 characters with truncation notice (no chunked synthesis in v1)

- **Decision**: If the input exceeds 5 000 characters after normalization, the controller truncates with a clear localized notice ("Crafted the first 5 000 characters; the rest was not synthesized"). No chunked synthesis is attempted.
- **Rationale**: Chunked synthesis would require concatenating MP3 frames (or re-encoding) which is non-trivial and risks audible glitches at boundaries. A clear truncation notice is honest, easy to reason about, and matches the user's intent (a study snippet, not a full article). The cap is conservative for ~3–5 minutes of speech at typical Azure Speech MP3 bitrates, well under the Azure Speech long-audio synthesis threshold.
- **Alternatives considered**:
  - Chunked synthesis with silence padding — deferred: future enhancement.
  - Reject long inputs outright — rejected: forces users to chunk themselves, which is a worse UX.

### D6. Same-language detection is UI-side only (no AI call when source == target)

- **Decision**: When the user is in Translate then speak mode and sets `sourceLanguage == targetLanguage`, the controller exposes a one-tap "Switch to Speak directly" affordance inline (no modal, no toast spam). The user can dismiss the suggestion and continue — at which point the flow will still call translation (which the LLM handles gracefully, usually returning the input unchanged).
- **Rationale**: A heuristic same-language detector based on text alone is unreliable (a single English sentence can be valid both English and code-switched). The affordance guides without forcing. Avoiding a translation call is a small bonus but not the primary mechanism.
- **Alternatives considered**:
  - Auto-detect language via an LLM call — rejected: extra cost, extra latency, low signal.
  - Hard-block Translate then speak when source == target — rejected: feels paternalistic; the affordance is enough.

### D7. Failure discard is enforced at the controller boundary, not the repository

- **Decision**: The Craft controller runs translate → synthesize → repository write in a single try block. If any stage throws, no repository write happens and the typed `CraftFailure` is surfaced to the UI. The repository is a thin write-and-return-id wrapper; it does not need to know about partial-failure cleanup.
- **Rationale**: Concentrating the discard logic at the controller boundary keeps the repository testable in isolation and makes the failure paths easy to audit (`grep -n 'throw CraftFailure' lib/features/craft/application/`).
- **Alternatives considered**:
  - Make the repository transactional across all writes — rejected: the only thing that needs discarding is in-memory state (no row was written yet at the time of failure); making the repository aware of partial-failure semantics would couple it to AI failure modes.

### D8. Reuse `MediaKind.audio` for Craft results (no video kind)

- **Decision**: Craft results are `MediaKind.audio` only. No video compositing, no background music, no visual artifacts.
- **Rationale**: The user described audio materials for shadow reading. Video is out of scope (spec Out of scope). Audio items participate in the existing library grid and player flow without any new presentation layer.
- **Alternatives considered**:
  - Add a `MediaKind.craft` or `MediaKind.tts` — rejected: gratuitous enum expansion when the existing audio media path already covers playback.

### D9. Library badge slot already exists — no widget changes for Craft badge

- **Decision**: `MediaCardTile` already accepts a `providerBadge` string parameter and renders it in the top-right of the cover. The library + home grid providers are extended with a single ternary check (`provider == 'youtube' ? l10n.youtubeBadge : provider == 'craft' ? l10n.libraryProviderCraftBadge : null`).
- **Rationale**: This is the same change shape as the YouTube badge in spec 0015. Zero new widget code; the badge renders identically to the YouTube badge.
- **Alternatives considered**:
  - Add a separate `CraftBadge` widget — rejected: gratuitous widget for a single string.
  - Reuse the YouTube badge style with a different icon — rejected: per-spec the badge should match the YouTube badge position and styling for consistency.

### D10. AI settings screen needs no layout changes; copy is updated to reflect TTS as first-class

- **Decision**: `lib/features/ai/presentation/settings/ai_providers_screen.dart` renders the four modality cards in a fixed order: LLM, ASR, TTS, assessment. This change does NOT reorder them; it only updates the TTS card subtitle (`settingsAiProvidersModalityTtsHint`) to remove the "limited" / P3 feel and adds a localized hint that Craft uses this provider.
- **Rationale**: Re-ordering risks user muscle-memory changes; promoting copy + docs is the minimal-impact change that lifts TTS from P3 to first-class without visual surprises.
- **Alternatives considered**:
  - Re-order to put TTS after LLM (since Craft + dictionary consume both) — deferred: not strictly needed for this feature.

## Best-practice patterns ported from `apps/web`

- **Single entry, two modes** — the user's UX requirement matches the web app's separation, but the player folds them into one import entry so there is no top-level "Smart Translation" or "Voice Synthesis" navigation. The web routes (`apps/web/src/routes/smart-translation.tsx`, `apps/web/src/routes/voice-synthesis.tsx`) are reference-only — not ported as standalone routes.
- **Per-call voice selection is deferred** — the web route has a `VoiceSelector` component (`apps/web/src/components/voice-synthesis/voice-selector.tsx`) which we are not porting in v1. Per-provider voice defaults in AI settings is the established way to pick a voice in the player.
- **TTS history** is replaced by the library + library search. The web app stores TTS results in `tts-cache`; in the player, Craft results are first-class audio media items that show up in the library grid and are searchable like any other audio. No separate cache.
- **Translation history** is replaced by the existing `translations` table (the same one auto-translate writes to in spec 009) — Craft's secondary transcript on the new audio row IS the durable record. The user does not see a separate translation history tab for Craft.

## References

- Web feature surfaces (reference only, not ports): `apps/web/src/routes/smart-translation.tsx`, `apps/web/src/routes/voice-synthesis.tsx`, `apps/web/src/components/smart-translation/`, `apps/web/src/components/voice-synthesis/`.
- Web capability wiring: `packages/ai/src/services/smart-translation-service.ts`, `packages/ai/src/services/tts-service.ts`, `packages/ai/src/capabilities/tts/byok.ts`, `packages/ai/src/capabilities/tts/byok-azure.ts`.
- Player existing imports: `lib/features/library/data/library_repository.dart` (`importMedia`, `importYoutubeVideo`), `lib/features/library/presentation/library_actions.dart` (`showImportChooser`, `importYoutubeFromDialog`).
- Player AI capability layer: `lib/features/ai/application/ai_capability_providers.dart`, `lib/features/ai/application/ai_services.dart`.
- Player Azure Speech SDK wiring: `packages/azure_speech/lib/azure_speech.dart`, `lib/features/ai/data/azure_assessment_runner.dart`, `lib/features/ai/data/enjoy/enjoy_assessment_capability.dart` (template for the Enjoy TTS implementation).
- Player BYOK secrets / config: `lib/data/api/byok_secret_store.dart`, `lib/features/ai/data/ai_modality_config_repository.dart`, `lib/features/ai/presentation/settings/ai_providers_screen.dart`.
- Constitution and ADRs that bound the design: `docs/decisions/0014-ai-capabilities-layer.md`, `docs/decisions/0017-azure-pronunciation-assessment.md`, `docs/decisions/0033-byok-ai-provider-settings.md`, `specs/003-byok-ai/spec.md`, `specs/009-transcript-auto-translate/spec.md`.