# Data Model: Craft from Text (AI-generated audio materials)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> **No Drift schema migration for v1.** Craft reuses the existing `Audios` and `Transcripts` tables — all Craft-specific information is stored in existing free-form columns (`provider`, `source`, `sourceText`, `translationKey`) and in new transcript rows. This mirrors the pattern used by spec 009 (auto-translate) which also introduced a new AI-driven media flow without schema changes.

## Entities

### AudioRow — Craft-generated audio (`Audios`)

One durable row per Craft attempt that succeeded. The same row layout is used for the new import path; Craft only sets existing columns to new values.

| Field | Craft usage |
|-------|-------------|
| `id` | `enjoyAudioId(aid: contentHash)` — stable across re-imports of the same text, dedupe via `getByMd5(md5)` mirrors `importYoutubeVideo`. |
| `aid` | `enjoyLocalAudioAid(contentHashHex, userId)` — same hash derivation as local-file imports so the audio row slots into sync the same way. |
| `provider` | **`'craft'`** — the library badge and sync routing key off this value. |
| `title` | First ~40 chars of the **learning-language** (primary) text, with an ellipsis if truncated. Same heuristic as the discover / home grid for media titles. |
| `description` | `null` (Craft does not generate descriptions in v1). |
| `thumbnailUrl` | `null` (Craft results use the deterministic generative cover like all audio items). |
| `durationSeconds` | Probed from the synthesized audio bytes via `ffmpeg -i` in a worker isolate — same probe path as `importMedia`. |
| `language` | Canonical BCP-47 base form of the learning language (e.g. `en`, `zh`). Matches existing `canonicalMediaLanguageTag`. |
| `translationKey` | For Translate then speak, the canonical source language tag; for Speak directly, equals `language`. Reused for sync translation-key lookups. |
| `sourceText` | The literal text the learner pasted. Persisted verbatim so future re-Craft can reproduce the audio without re-asking the learner. |
| `voice` | Vendor-default voice id resolved at synthesis time (OpenAI: `'alloy'`; Azure Speech: the provider-default voice for the target language, or the configured `model` from `SpeechByokConfig` when BYOK Azure is active). `null` if the vendor did not surface one. |
| `source` | **`'craft-translate'`** for Translate then speak; **`'craft-direct'`** for Speak directly. Distinguishes Craft rows from `'craft'` placeholder rows and supports future per-mode analytics / sync rules. |
| `localUri` | File URI of the synthesized audio file in app storage (path returned by `FileStorage.importBytes`). Always populated; offline-only Craft is out of scope. |
| `md5` | SHA-256 over `mode + '|' + canonicalLanguage + '|' + canonicalText` (NFC-normalized, whitespace-collapsed). Used for dedupe + sync identity, mirroring the local-file import convention. |
| `size` | Byte count of the synthesized audio file. |
| `mediaUrl` | `null` (Craft is always local; no remote URL). |
| `syncStatus` | `'pending'` initially; existing audio sync pipeline flips it to `'synced'` once uploaded. |
| `serverUpdatedAt` | `null` until first successful sync. |
| `createdAt` / `updatedAt` | Set on insert; `updatedAt` bumped on any patch (e.g. duration probe). |

### TranscriptRow — Craft primary transcript (`Transcripts`)

One row per Craft item, storing the learning-language text used as the primary transcript.

| Field | Craft usage |
|-------|-------------|
| `id` | `enjoyTranscriptId('audio', mediaId, language, 'ai')` — stable id derivation, matches spec 009. |
| `targetType` | `'Audio'` |
| `targetId` | `AudioRow.id` |
| `language` | Learning language (canonical base tag). |
| `source` | `'ai'` (reuses the spec 009 convention so existing transcript list UIs already know how to label it). |
| `timelineJson` | Single-line timeline `{text: learningText, start: 0, duration: <probed duration ms>}` for Speak directly mode; or a sentence-split timeline (LLM-friendly chunking, paragraph-aware) for Translate then speak mode. Implementation detail — the player accepts any timeline shape and renders cues. |
| `referenceId` | For Translate then speak: the source language tag (so the secondary transcript can look it up). For Speak directly: `null`. |
| `label` | Localized "Learning language" label (e.g. `l10n.transcriptTrackLearning`). |
| `trackIndex` | `null` |
| `syncStatus` | `'local'` (Craft transcripts do not sync to cloud in v1 — they are generated on device; same convention as spec 009). |
| `serverUpdatedAt` | `null` |
| `createdAt` / `updatedAt` | Set on insert. |

### TranscriptRow — Craft secondary transcript (`Transcripts`, Translate then speak only)

Inserted only when `mode == translateThenSpeak`. Mirrors spec 009's bilingual track pattern.

| Field | Craft usage |
|-------|-------------|
| `id` | `enjoyTranscriptId('audio', mediaId, sourceLanguage, 'ai')` — distinct from primary id by language component. |
| `targetType` | `'Audio'` |
| `targetId` | `AudioRow.id` |
| `language` | Source language (canonical base tag). |
| `source` | `'ai'` |
| `timelineJson` | Single-line timeline `{text: sourceText, start: 0, duration: <probed duration ms>}`. The player renders this as the secondary (translation) line under each primary cue. |
| `referenceId` | `primary_transcript.id` so the secondary can be invalidated when the primary is regenerated. |
| `label` | Localized "Source" label. |
| `syncStatus` | `'local'` |
| `createdAt` / `updatedAt` | Set on insert. |

### EchoSessionRow — selection wiring

| Field | Craft usage |
|-------|--------------|
| `transcriptId` | Set to the Craft primary transcript id when echo mode is opened on the Craft item. Same selection pattern as any other audio item. |
| `secondaryTranscriptId` | Set to the Craft secondary transcript id for Translate then speak items; `null` for Speak directly items. |

### CraftJob (logical, in-memory)

Not persisted. Owned by the Craft controller per session.

| Field | Notes |
|-------|-------|
| `mode` | `CraftMode.translateThenSpeak` or `CraftMode.speakDirectly`. Persisted as `Audios.source`. |
| `text` | Raw user-entered text. |
| `normalizedText` | NFC-normalized + whitespace-collapsed form used for hashing and as synthesis input. |
| `sourceLanguage` | Set in Translate then speak; `null` in Speak directly. |
| `targetLanguage` | The learning language for both modes. |
| `status` | `idle` \| `validating` \| `translating` \| `synthesizing` \| `saving` \| `completed` \| `failed`. |
| `stage` | The current step label surfaced to the UI (calm, no jargon). |
| `failure` | `null` or one of `CraftFailure.translate` / `CraftFailure.tts` / `CraftFailure.save` / `CraftFailure.signInRequired` / `CraftFailure.offline` / `CraftFailure.sameLanguage`. |
| `generation` | Monotonic counter — incremented on each new submit so stale completions are discarded. |
| `resultMediaId` | Set on `completed`; used to navigate to the player. |
| `dedupedExistingId` | Set when the same content hash already exists; `CraftFlow` surfaces "Already in your library" with **Open** instead of opening a new player. |

### CraftFailure (logical)

| Kind | UI mapping |
|------|------------|
| `translate` | "We couldn't translate the text" + Retry + switch-to-Speak-directly affordance. |
| `tts` | "We couldn't turn the text into audio" + Retry + Open AI settings (when BYOK is misconfigured). |
| `save` | "The audio was generated but couldn't be saved" + Retry; user frees up space. |
| `signInRequired` | Routes through the existing sign-in affordance (per spec 003 sign-in handling). |
| `offline` | Calm banner copy at the top of the sheet; action disabled. |
| `sameLanguage` | One-tap "Switch to Speak directly" affordance in Translate then speak mode. |
| `vendorUnsupportedLanguage` | "TTS doesn't support this language" + recommend switching target / TTS vendor. |

## Relationships

```text
CraftJob (in-memory)
    │
    │ translate (Translate then speak)
    ▼
TranslationService  ──▶  translatedText
    │
    │ synthesize (TTS, Enjoy AI or BYOK via TtsService)
    ▼
TtsResult(audioBytes, format, durationMs)
    │
    │ importCraftedFromText(...)
    ▼
AudioRow (provider = 'craft', sourceText = text, source = mode flag)
    │
    ├──▶ TranscriptRow primary (language = learning, source = 'ai', referenceId = sourceLanguage)
    │
    └──▶ TranscriptRow secondary (Translate then speak only; language = source, source = 'ai', referenceId = primary.id)

EchoSessionRow
    ├── transcriptId      = primary.id
    └── secondaryTranscriptId = secondary.id (Translate then speak) | null (Speak directly)
```

## Validation rules

1. `text.trim().length >= 10` — shorter inputs cannot be Crafted (FR-023). UI disables the action.
2. `text.trim().length <= 5000` — longer inputs are truncated with a clear notice (research D5).
3. `sourceLanguage` is required for Translate then speak; `null` is accepted for Speak directly.
4. `targetLanguage` MUST equal the profile learning language at submit time. If the user picked a different target, the controller shows a localized note ("Craft will save this to your <language> library") and proceeds — same convention as the existing content-language picker in `importYoutubeFromDialog`.
5. Re-import with the same `(mode, language, normalizedText)` hash returns the existing row id (no new audio bytes written, no API calls made) — dedupe per research D4.
6. Failure at any stage discards in-memory state; no orphan rows are written.
7. Library insertion is atomic: a single Drift transaction wraps `AudioDao.insertRow` + the two `TranscriptDao.upsert` calls (primary + optional secondary). If any fails, all are rolled back.
8. EchoSession wiring happens after the media row exists; it does not block the controller's `completed` state.
9. Sync is enqueued once per Craft item via `SyncEnqueueFn(SyncEntityType.audio, id, SyncAction.create)` — same plumbing as `importMedia` and `importYoutubeVideo`.

## State transitions

```text
              user opens Craft sheet
                       │
                       ▼
                  CraftJob(idle)
                       │ user edits fields
                       ▼
                  CraftJob(idle, dirty)
                       │
                       │ submit()
                       ▼
                  CraftJob(validating)
                  ─ eligibility OK?
                       │
        ┌──────────────┼─────────────────────────┐
        no             yes                        no (same lang, Translate)
        │              │                         │
        ▼              ▼                         ▼
   failed(signIn/    CraftJob(translating)     hint surfaced; user
   offline/empty)    ─ Translate then speak only    taps to switch
        │              │
        │              ▼
        │           translate error → failed(translate); discard
        │              │
        │              ▼
        │           CraftJob(synthesizing)        Speak directly
        │              │                         skips translating
        │              ▼
        │           synthesize error → failed(tts); no rows written
        │              │
        │              ▼
        │           CraftJob(saving)
        │              │
        │              ▼
        │           importCraftedFromText → success: CraftJob(completed, mediaId)
        │              │       or
        │              ▼
        │           save error → failed(save); no rows written
        │
        └─── Retry ───▶ CraftJob(validating, generation++)
```

## UI state mapping (non-persisted)

| Job state | Learner-facing cue |
|-----------|--------------------|
| `idle`, `text.trim().length < 10` | Craft action disabled with hint "Enter at least a sentence to craft." |
| `idle`, `text.trim().length > 5000` | Inline "Crafted the first 5 000 characters" notice above the action. |
| `validating`, `signInRequired` | Sign-in callout card replacing the action; routed through existing auth surface. |
| `validating`, `offline` | Calm offline banner at top of sheet; action disabled. |
| `translating` / `synthesizing` | Import-blocking dialog with stage label ("Crafting your audio…"). |
| `sameLanguage` (Translate then speak) | Inline suggestion chip: "Looks like this is already in your learning language." + Speak-directly button. |
| `completed` | Sheet closes; player opens with the new audio. |
| `failed(translate)` | Inline sheet error with Retry + "Switch to Speak directly" affordance. |
| `failed(tts)` | Inline sheet error with Retry + Open AI settings (when BYOK was the cause). |
| `failed(save)` | Inline sheet error with Retry. |
| `dedupedExistingId` set | "Already in your library" callout + Open button; import dialog closes without playing the new audio. |