# Contracts: Craft from Text (AI-generated audio materials)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> Craft introduces **one** new public contract (the repository import method) and reuses every existing cross-feature contract (translation, TTS, Azure token cache, file storage, sync, library queries). The contracts documented here are the **integration points** between the new Craft feature module and the rest of the player, expressed as Dart method signatures with their semantic invariants. No new HTTP endpoints, no new SQL tables, no new platform channels are introduced in this change.

---

## C1. `MediaLibraryRepository.importCraftedFromText` (NEW)

**Module**: `lib/features/library/data/library_repository.dart`

**Signature**:

```dart
/// Persists a synthesized audio + (optional) transcript pair produced by
/// the Craft flow. Returns the new (or existing) media id.
///
/// See `specs/010-craft-from-text/data-model.md` for the row layout and
/// `specs/010-craft-from-text/plan.md` § Implementation Notes for the
/// caller-side discard invariants.
Future<String> importCraftedFromText({
  required Uint8List audioBytes,
  required String audioFormat,
  required CraftMode mode,                 // translateThenSpeak | speakDirectly
  required String learningLanguage,        // canonical BCP-47 base
  String? sourceLanguage,                  // required when mode == translateThenSpeak
  required String text,                    // raw user-entered text
  required String normalizedText,          // NFC + whitespace-collapsed
  required String signedInUserId,
}) async
```

**Invariants**:

- MUST dedupe by `SHA-256('${mode.name}|${learningLanguage}|${normalizedText}')`. If a row with the same `md5` exists, return its id and skip all writes + sync enqueue.
- MUST write audio bytes via `FileStorage.importBytes(audioBytes, extension: audioFormat)`.
- MUST insert one `AudioRow` with `provider = 'craft'`, `source = mode == translateThenSpeak ? 'craft-translate' : 'craft-direct'`, `language = learningLanguage`, `translationKey = sourceLanguage ?? learningLanguage`, `sourceText = text`, `md5 = <hash>`, `localUri = <result.fileUri>`, `size = audioBytes.length`.
- MUST insert one `Transcripts` row with `source = 'ai'`, `language = learningLanguage`, `targetType = 'Audio'`, `targetId = <new audio id>`, `referenceId = sourceLanguage` (translate mode) or `null` (direct mode), `timelineJson = JSON of one-line or sentence-split timeline`, `syncStatus = 'local'`.
- IF `mode == translateThenSpeak`, MUST also insert a secondary `Transcripts` row with `language = sourceLanguage`, `referenceId = primary.id`, `timelineJson = JSON of one-line timeline for the source text`.
- MUST enqueue sync via `SyncEnqueueFn(SyncEntityType.audio, id, SyncAction.create)` exactly once.
- MUST run the audio row insert, primary transcript upsert, and (conditional) secondary transcript upsert in a single Drift transaction so partial failures roll back cleanly.
- MUST probe `durationSeconds` from the synthesized audio via the existing `ffmpeg -i` worker-isolate probe (same path as `importMedia`).
- Throws `FileFailure` on storage write failure (mapped to `AppFailure` upstream).
- Returns the media id (string).

---

## C2. `TtsService.synthesize` (UNCHANGED — call site)

**Module**: `lib/features/ai/application/ai_services.dart`

**Signature**:

```dart
final class TtsService {
  TtsService(this._ref);
  final Ref _ref;
  Future<TtsResult> synthesize(TtsRequest request);
}
```

**Invariants for Craft callers**:

- MUST route through `ttsCapabilityProvider`, which already selects `EnjoyTtsCapability` / `ByokTtsOpenAiCapability` / `ByokTtsAzureCapability` / `ByokNotConfiguredTtsCapability` / `UnimplementedTtsCapability` based on `aiModalityConfigsProvider`.
- `TtsRequest.text` MUST be the learning-language text (translated text for Translate then speak; original text for Speak directly).
- `TtsRequest.language` MUST be the canonical base form of the learning language.
- `TtsRequest.voice` is optional; provider-default voice is used when `null`.
- Throws `ByokNotConfiguredFailure` (mapped to friendly Craft failure with "Open AI settings" affordance).
- Throws `ApiException` on vendor auth / rate limit / network failures (mapped via `guardAiCall`).

**Implementation gap closed in this change**: `EnjoyTtsCapability.synthesize` is currently a stub throwing `UnimplementedError`. This plan replaces it with an Azure Speech SDK call (token cache + native synthesize) per research D1.

---

## C3. `TranslationService.translate` (UNCHANGED — call site)

**Module**: `lib/features/ai/application/ai_services.dart`

**Signature**:

```dart
final class TranslationService {
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  });
}
```

**Invariants for Craft callers**:

- Routes through `translationCapabilityProvider` (Enjoy or BYOK per `aiModalityConfigsProvider`).
- `sourceLanguage` and `targetLanguage` MUST be canonical BCP-47 base tags.
- Returns `TranslationResult.translatedText` — the Craft controller uses this as the TTS input for Translate then speak.
- Throws on auth, rate limit, network (mapped via `guardAiCall`); Craft controller maps to `CraftFailure.translate`.

---

## C4. `AzureTokenCache.getToken` (EXTENDED — `purpose: 'tts'`)

**Module**: `lib/data/api/services/ai/azure_token_cache.dart`

**Existing signature**:

```dart
Future<({String token, String region})> getToken({required int durationSeconds});
```

**Change in this plan**: the `usage` payload sent to `POST /azure/tokens` is extended from `'purpose': 'assessment'` to support `'purpose': 'tts'` (with no assessment block). The signature on the Dart side stays the same; an optional named arg `purpose: 'tts'` (default `'assessment'` for back-compat) is added.

**Invariants for Craft callers**:

- `EnjoyTtsCapability.synthesize` calls `getToken(durationSeconds: estimatedSeconds, purpose: 'tts')`.
- The cache remains in-memory (~9 min TTL); Craft tokens are short-lived and not persisted to disk.
- Throws `StateError` if the worker response is malformed (no token / region).
- `clear()` is exposed for tests and for force-refresh paths.

---

## C5. Library provider badge wiring (UNCHANGED — call site)

**Module**: `lib/features/library/presentation/widgets/local_library_tab_view.dart`, `home_screen.dart`

**Pattern**: existing library and home grid builders read each media item's `provider` and pass a localized badge string to `MediaCardTile`. The Craft change adds one more ternary arm:

```dart
providerBadge: switch (media.provider) {
  'youtube' => l10n.youtubeBadge,
  'craft'   => l10n.libraryProviderCraftBadge,   // NEW
  _         => null,
},
```

**Invariant**: `MediaCardTile` renders the badge in the same top-right slot it already uses for YouTube. No widget changes.

---

## C6. AI provider settings card (UNCHANGED — copy only)

**Module**: `lib/features/ai/presentation/settings/ai_providers_screen.dart`, `ai.md`

The four-card surface (LLM, ASR, TTS, assessment) already exists; TTS card already renders with `settingsAiProvidersModalityTts` + `settingsAiProvidersModalityTtsHint`. This plan updates the localized TTS subtitle hint to remove any "P3" / "limited" feel and adds a `craftTtsSettingsHint` line so users understand Craft consumes the TTS modality.

**Invariant**: no widget, no layout, no order change. Copy-only.

---

## C7. Import chooser sheet (UNCHANGED — one more ListTile)

**Module**: `lib/features/library/presentation/library_actions.dart`

The existing `showImportChooser` adds one `ListTile` after the YouTube one:

```dart
ListTile(
  leading: const Icon(Icons.auto_awesome_outlined),
  title: Text(l10n.importCraftFromText),
  onTap: () {
    Navigator.pop(ctx);
    unawaited(showCraftSheet(context, ref));
  },
),
```

**Invariant**: list order is Local → YouTube → Craft. Sheet close + sheet-open follows the same pattern as the existing two entries.

---

## Cross-feature shortcut justification

Craft calls `TranslationService` and `TtsService` directly — these are intentional cross-feature calls because both services are explicitly designed as AI capability entry points (spec 003 / ADR-0014). No new shortcut is introduced: Craft does NOT reach into the library repo for read queries, does NOT touch Drift directly, and does NOT bypass the existing `aiModalityConfigsProvider` for provider resolution.

The new `MediaLibraryRepository.importCraftedFromText` is the single new integration point. It mirrors the shape of `importMedia` and `importYoutubeVideo` so the controller, repository, and DAO layers remain testable in isolation.