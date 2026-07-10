# Contract: `AsrCapability` (unchanged, contract reference)

This is the contract the new generation flow **consumes**. It is already
implemented in `lib/features/ai/`. Re-stated here so the plan and the
quickstart have a single source of truth.

```dart
// lib/features/ai/domain/capabilities/asr_capability.dart
abstract class AsrCapability {
  Future<AsrResult> transcribe(AsrRequest request);
}
```

```dart
// lib/features/ai/domain/models/asr_request.dart
final class AsrRequest {
  final Uint8List audioBytes;     // WAV for Azure; any codec for Whisper
  final String filename;          // e.g. 'asr-<uuid>.wav' for temp file naming
  final String? mimeType;
  final String? model;            // Whisper model name (enjoy + BYOK OpenAI)
  final String? language;         // BCP47 base tag; null = auto-detect (Enjoy only)
  final String? prompt;           // Whisper hot-word prompt
  final String responseFormat;    // 'json' | 'text' | 'vtt'
  final double? durationSeconds;  // server-side billing cap hint
}
```

```dart
// lib/features/ai/domain/models/asr_result.dart
final class AsrResult {
  final String text;
  final List<AsrSegment>? segments;   // Whisper-style segment timings
  final String? language;             // auto-detected language (Enjoy only)
  final double? duration;
  final int? wordCount;
}

final class AsrSegment {
  final double start;   // seconds
  final double end;     // seconds
  final String text;
  final List<AsrWord>? words;
}

final class AsrWord {
  final String word;
  final double start;   // seconds
  final double end;     // seconds
}
```

**Resolution path** (`resolveAsrCapability(ref, config)` in
`lib/features/ai/application/ai_capability_providers.dart`):

| `AIProvider` | `SpeechByokKind` | Implementation |
|---|---|---|
| `enjoy` | n/a | `EnjoyAsrCapability` → `AsrApi.transcribe` (Enjoy worker `/audio/transcriptions`) |
| `byok` | `openAiCompatible` | `ByokAsrOpenAiCapability` → `postWhisperTranscription` |
| `byok` | `azureSpeech` | `ByokAsrAzureCapability` → `AzureSpeech.instance.transcribe` |
| `local` | n/a | `UnimplementedAsrCapability` (throws) |

**Failure modes** (already surfaced by existing AI plumbing via
`guardAiCall` and consumed by `ai_byok_error_mapping.dart`):

- `ByokNotConfiguredFailure(ModalityKind.asr)` — missing BYOK API key.
- `ApiException(message, statusCode, body)` — provider HTTP errors.
- `AzureSpeechException` — Azure SDK errors (BYOK Azure).
- `StateError` — config mismatch (e.g. BYOK Azure without region).

All four are caught and re-thrown as `AppFailure` subclasses in
`core/errors/app_failure.dart` so the UI layer never sees raw
exceptions (FR-017 / SC-007).

---

# Contract: `AsrGenerationController` (new)

A new application-layer controller wires the end-to-end flow. It is the
**only** entry point the UI calls.

```dart
// lib/features/asr/application/asr_generation_controller.dart
@riverpod
class AsrGenerationController extends _$AsrGenerationController {
  // ListenableStateNotifier-style — exposes AsyncValue<AsrGenerationJob?>
}
```

**Public API**:

```dart
/// Starts an ASR generation job. Returns a Future that completes when
/// the job is done (success, error, or cancellation). The same controller
/// exposes `state` (the latest `AsrGenerationJob`) for UI binding.
///
/// If a job is already in-flight for [mediaId], the prior job's future
/// is cancelled cleanly (FR-015) before the new one starts.
Future<void> generateTranscript({
  required String mediaId,
  String? language,          // null → use media row's stored language
  bool confirmLongMedia = true, // pre-flight dialog when duration ≥ 30 min
});

/// Cancels the in-flight job (if any) for [mediaId]. The job's future
/// completes with `AsrGenerationPhase.cancelled` and no row is written.
Future<void> cancel(String mediaId);

/// Drops the latest job from state (used by the picker / empty state
/// after the user dismisses the success toast).
void clear(String mediaId);
```

**State observation** (UI listens via `ref.watch`):

```dart
final state = ref.watch(asrGenerationControllerProvider(mediaId));
// state is AsyncValue<AsrGenerationJob?>
```

`AsyncValue` is used so the existing loading/error UX (`when(...)` with
spinner + friendly message) reuses the same widgets already used by
`TranscriptFetchCtrl`.

---

# Contract: `TranscriptRepository.upsertAsrGeneratedTrack` (new)

```dart
// added to lib/features/transcript/data/transcript_repository.dart
Future<String?> upsertAsrGeneratedTrack({
  required String mediaId,
  required String language,
  required List<TranscriptLine> lines,
  String? label,             // preserved across re-generation
  bool activateAsPrimary = true,
});
```

**Behaviour** (see `data-model.md` §3.2):
- Builds a deterministic row id (`enjoyTranscriptId(...source: 'ai')`).
- Replaces any existing row at that id (`upsert`).
- When `activateAsPrimary == true`, calls `ensurePrimaryTranscript` so
  the new track becomes the session's active primary.
- Returns the row id, or `null` when the media id cannot be resolved.

This is the only contract surface added to `TranscriptRepository`.

---

# Contract: `AsrAudioExtractor` (new)

```dart
// lib/features/asr/data/asr_audio_extractor.dart
final class AsrAudioExtractor {
  const AsrAudioExtractor();

  /// Returns the audio bytes to feed to AsrCapability.
  ///
  /// For audio-only sources (uri matches a recognized audio MIME or
  /// extension), returns the raw bytes of [mediaSourceUri].
  ///
  /// For video sources, extracts the audio track to a normalized WAV
  /// (16 kHz mono 16-bit PCM when Azure-preferred), then reads the bytes
  /// back and deletes the temp file in `finally`.
  ///
  /// Throws [AsrAudioExtractionException] for:
  /// - FFmpeg not available on PATH / not bundled
  /// - Container has no audio stream
  /// - FFmpeg exit code != 0
  /// - File size above `maxBytes` (default 500 MB) to prevent OOM
  Future<Uint8List> extractAudio({
    required String mediaSourceUri,
    required MediaKind kind,
    void Function(double progress)? onProgress,
    int maxBytes = 500 * 1024 * 1024,
  });
}

enum MediaKind { audio, video }

class AsrAudioExtractionException implements Exception {
  final AsrAudioExtractionFailureReason reason;
  final String? message;
  AsrAudioExtractionException(this.reason, [this.message]);
  @override
  String toString() => message ?? reason.name;
}

enum AsrAudioExtractionFailureReason {
  ffmpegUnavailable,
  noAudioTrack,
  ffmpegFailed,
  fileTooLarge,
  unsupportedSource,
}
```

The reason codes drive the localized error messages used by the UI
(FR-017 / SC-007):

| Reason | User-facing message key |
|---|---|
| `ffmpegUnavailable` | `asrErrorFfmpegUnavailable` (link → Settings → FFmpeg install hint) |
| `noAudioTrack` | `asrErrorNoAudioTrack` |
| `ffmpegFailed` | `asrErrorExtractionFailed` (with `Retry`) |
| `fileTooLarge` | `asrErrorFileTooLarge` |
| `unsupportedSource` | `asrErrorUnsupportedSource` |

---

# Contract: `AsrTimelineBuilder.buildAsrTranscriptLines` (new)

Pure function, no I/O. Full signature and behaviour in
`data-model.md` §2.3. The contract for callers is:

- **Input**: an `AsrResult` plus the media's total duration in ms.
- **Output**: zero or more `TranscriptLine`s with `startMs` /
  `durationMs` in milliseconds.
- **Side effects**: none.
- **Determinism**: identical input + duration → identical output, so
  re-generation of the same audio produces a byte-equal `timelineJson`.

---

# Contract: Subtitles picker / empty-state integration (UI)

No new public surface on widgets beyond what already exists. The empty
state and the picker gain an optional callback parameter:

```dart
class TranscriptEmptyState extends StatelessWidget {
  const TranscriptEmptyState({
    required this.onImport,
    this.onExtract,
    this.onGenerate,             // NEW
    this.showGenerateButton = false, // NEW
    this.showImportButton = true,
    this.showExtractButton = false,
    super.key,
  });

  final Future<void> Function()? onGenerate;
}

class SubtitleActionsSection extends StatelessWidget {
  const SubtitleActionsSection({
    super.key,
    required this.horizontalPadding,
    required this.showExtractEmbedded,
    required this.showImportFile,
    required this.onExtractEmbedded,
    required this.onRefreshCloud,
    required this.onImportFile,
    this.onGenerate,             // NEW
    this.showGenerate,           // NEW
  });

  final Future<void> Function()? onGenerate;
  final bool showGenerate;
}
```

Both callbacks resolve to a `Future<void>` that the calling code wires
to `AsrGenerationController.generateTranscript(...)`. The widgets
themselves do not import anything from `lib/features/asr/`.