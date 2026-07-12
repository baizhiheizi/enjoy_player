# ADR-0043: Craft from Text Import

**Date**: 2026-07-09 · **Status**: Accepted

## Context

Enjoy Player supports local files and YouTube videos as practice materials.
Some learners want to "homecook" their own materials — pasting a paragraph of
text and generating synthesized audio for shadow reading. The Enjoy web app
implements this as two separate routes: "Smart Translation" (text → translate)
and "Voice Synthesis" (text → TTS). The user requirement for the player is to
**redesign the UX**: fold both capabilities into a single import entry beside
"From file" and "From YouTube URL", rather than exposing them as separate
top-level destinations.

Behind the scenes, the feature reuses the existing AI capability layer
(`TranslationService`, `TtsService`) but requires closing one gap: the Enjoy
TTS path was a stub (`UnimplementedError`).

## Decision

1. **Single import entry**: Add a third option "Craft from text…" to the
   existing import chooser sheet (`showImportChooser`). There is **no**
   standalone "Smart Translation" or "Voice Synthesis" navigation route in
   the player.

2. **Two modes within the Craft flow**:
   - **Translate then speak** — translate source text → learning language,
     then synthesize.
   - **Speak directly** — synthesize directly from learning-language text.
   Both modes share one `CraftSheet` widget with a segmented mode toggle.

3. **Provider value `craft`**: Craft-generated audio items store
   `Audios.provider = 'craft'` and `Audios.source = 'craft-translate' |
   'craft-direct'`. No Drift schema migration is needed — the `provider`
   and `source` columns are free-form text.

4. **Enjoy TTS via Azure Speech SDK + worker token** (parallel to Enjoy
   assessment): `EnjoyTtsCapability` fetches a short-lived Azure token via
   `AzureTokenCache.getToken(purpose: 'tts')` and calls
   `AzureSpeech.instance.synthesize(...)`. The BYOK TTS path (OpenAI / Azure
   Speech) was already implemented per spec 003; this change only wires the
   Enjoy default.

5. **TTS BYOK promoted to first-class**: The existing `ModalityProviderCard`
   for TTS in AI settings is no longer P3 — it is a first-class surface on
   equal footing with ASR and assessment. The capability layer was already
   implemented; this change is copy + docs.

6. **Dedupe by content hash**: `SHA-256(sourceFlag|learningLanguage|
   normalizedText)`. Re-pasting the same text returns the existing media id
   without making any AI calls.

7. **Failure discard at the controller boundary**: Translate / synthesize /
   save run in a single try block. If any stage fails, no repository write
   happens — no orphan transcript rows or audio files.

## Consequences

- **Positive**: One import surface for all three source types (local, YouTube,
  text). Reuses existing AI capability layer without a new service. Echo mode
  and library badges work without extra wiring because Craft items are
  regular audio media items.

- **Negative**: The Enjoy TTS path depends on the Azure Speech SDK on all four
  platforms (Android, iOS, macOS, Windows). Platform-channel smoke testing is
  required per release.

- **Neutral**: Voice selection per Craft call is deferred to v1; the provider-
  default voice is used. Per-call voice pickers can be added later in the AI
  settings or the Craft sheet.

## References

- [Spec: Craft from Text](../../specs/010-craft-from-text/spec.md)
- [Plan: Craft from Text](../../specs/010-craft-from-text/plan.md)
- [ADR-0014: AI Capabilities Layer](0014-ai-capabilities-layer.md)
- [ADR-0017: Azure Pronunciation Assessment](0017-azure-pronunciation-assessment.md)
- Spec 003: BYOK AI Provider Settings
- Spec 009: Transcript Auto-Translate (transcript `source = 'ai'` convention)
