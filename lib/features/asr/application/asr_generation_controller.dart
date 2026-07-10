/// End-to-end ASR transcript generation controller.
///
/// Orchestrates the pipeline:
///   1. Resolve media (target type) — refuse unknown mediaIds.
///   2. Extract audio (skip for audio-only sources).
///   3. Call [AsrService.transcribe] (uses the configured provider).
///   4. Build a [TranscriptLine] timeline via [buildAsrTranscriptLines].
///   5. Upsert a deterministic `source: 'ai'` row via
///      [TranscriptRepository.upsertAsrGeneratedTrack].
///   6. Update the media row's language when the ASR result reports a
///      different language (FR-012).
///
/// Cancellation: a per-`mediaId` [Completer] acts as the cancel token.
/// Starting a new pass cancels the prior in-flight [Future] cleanly
/// (FR-015). UI binds to `state` (a `AsyncValue<AsrGenerationJob?>`).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/asr/domain/asr_audio_extraction_failure.dart';
import 'package:enjoy_player/features/asr/domain/asr_timeline_builder.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';

part 'asr_generation_controller.g.dart';

final Logger _log = logNamed('asr.controller');

@Riverpod(keepAlive: true)
class AsrGenerationController extends _$AsrGenerationController {
  Completer<void>? _cancelToken;
  Future<void>? _inFlight;

  @override
  AsyncValue<AsrGenerationJob?> build(String mediaId) {
    ref.onDispose(() {
      _cancelToken?.complete();
      _cancelToken = null;
    });
    return const AsyncValue.data(null);
  }

  /// Whether a generation is currently in flight for [mediaId].
  bool get isInFlight => _inFlight != null;

  /// Starts (or supersedes) a generation pass. Returns a [Future] that
  /// completes when the pass is done (success, error, or cancellation).
  Future<void> generateTranscript({
    String? language,
    bool autoDetect = false,
    bool confirmLongMedia = true,
    String? mediaSourceUri,
    MediaKind kind = MediaKind.video,
  }) async {
    // Cancel any prior in-flight job cleanly (FR-015).
    final prior = _cancelToken;
    if (prior != null && !prior.isCompleted) {
      prior.complete();
    }
    final cancel = Completer<void>();
    _cancelToken = cancel;

    final fallbackLanguage = await _resolveLanguage(null, mediaId);
    if (fallbackLanguage == null) {
      _setError('asrErrorGeneric');
      return;
    }
    final effectiveLanguage = autoDetect
        ? null
        : (language?.trim().isNotEmpty == true
              ? language!.trim()
              : fallbackLanguage);
    final trackFallbackLanguage = effectiveLanguage ?? fallbackLanguage;

    state = AsyncValue.data(
      AsrGenerationJob(
        mediaId: mediaId,
        language: trackFallbackLanguage,
        phase: AsrGenerationPhase.idle,
        startedAt: DateTime.now(),
      ),
    );

    final future = _run(
      cancel: cancel,
      requestedLanguage: effectiveLanguage,
      fallbackLanguage: trackFallbackLanguage,
      mediaSourceUri: mediaSourceUri,
      kind: kind,
    );
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  /// Cancels the in-flight job (if any) for [mediaId]. The job's future
  /// completes with `AsrGenerationPhase.cancelled`; no row is written.
  Future<void> cancel() async {
    final c = _cancelToken;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Clears the latest terminal state so the UI can re-trigger without
  /// holding the previous `errorMessage`.
  void clear() {
    state = const AsyncValue.data(null);
  }

  Future<String?> _resolveLanguage(String? override, String mediaId) async {
    if (override != null && override.isNotEmpty) return override;
    final db = ref.read(appDatabaseProvider);
    final tt = await dexieTargetTypeForId(db, mediaId);
    if (tt == null) return null;
    if (tt == 'Video') {
      final v = await db.videoDao.getById(mediaId);
      if (v != null && v.language.isNotEmpty) return v.language;
    } else if (tt == 'Audio') {
      final a = await db.audioDao.getById(mediaId);
      if (a != null && a.language.isNotEmpty) return a.language;
    }
    return 'en';
  }

  Future<void> _run({
    required Completer<void> cancel,
    required String? requestedLanguage,
    required String fallbackLanguage,
    required String? mediaSourceUri,
    required MediaKind kind,
  }) async {
    final startedAt = DateTime.now();
    Uint8List? audio;
    try {
      // 1. Extract audio (skip for audio-only files).
      if (kind == MediaKind.video) {
        if (mediaSourceUri == null || mediaSourceUri.isEmpty) {
          _setError('asrErrorUnsupportedSource');
          return;
        }
        _setPhase(AsrGenerationPhase.extracting);
        final extractor = ref.read(asrAudioExtractorProvider);
        try {
          audio = await extractor.extractAudio(
            mediaSourceUri: mediaSourceUri,
            kind: kind,
            onProgress: (p) {
              if (cancel.isCompleted) return;
              _updateJob((j) => j.copyWith(progress: p));
            },
          );
        } on AsrAudioExtractionException catch (e) {
          _log.info('Audio extraction failed: ${e.reason.name}');
          _setError(asrExtractionMessageKey(e.reason));
          return;
        }
      } else if (mediaSourceUri != null && mediaSourceUri.isNotEmpty) {
        try {
          final extractor = ref.read(asrAudioExtractorProvider);
          audio = await extractor.extractAudio(
            mediaSourceUri: mediaSourceUri,
            kind: kind,
          );
        } on AsrAudioExtractionException catch (e) {
          _setError(asrExtractionMessageKey(e.reason));
          return;
        }
      } else {
        _setError('asrErrorUnsupportedSource');
        return;
      }

      if (cancel.isCompleted) {
        _setCancelled();
        return;
      }

      // 2. Recognition.
      _setPhase(AsrGenerationPhase.recognizing);
      final asrService = ref.read(asrServiceProvider);
      final req = AsrRequest(
        audioBytes: audio,
        filename: 'asr-${mediaId.hashCode}.wav',
        language: requestedLanguage,
        responseFormat: 'json',
      );
      final AsrResult result;
      try {
        result = await asrService.transcribe(req);
      } on ByokNotConfiguredFailure catch (_) {
        _setError('asrErrorByokMissing');
        return;
      } on Object catch (e, st) {
        _log.warning('ASR call failed', e, st);
        _setError(_mapProviderError(e));
        return;
      }

      if (cancel.isCompleted) {
        _setCancelled();
        return;
      }

      // 3. Build the timeline.
      final mediaDurationMs = await _resolveMediaDurationMs(mediaSourceUri);
      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: mediaDurationMs,
      );
      if (lines.isEmpty) {
        _setError('asrErrorNoSpeech');
        return;
      }

      if (cancel.isCompleted) {
        _setCancelled();
        return;
      }

      // 4. Persist.
      _setPhase(AsrGenerationPhase.persisting);
      final repo = ref.read(transcriptRepositoryProvider);
      final trackLanguage = result.language?.trim().isNotEmpty == true
          ? result.language!.trim()
          : fallbackLanguage;
      final trackId = await repo.upsertAsrGeneratedTrack(
        mediaId: mediaId,
        language: trackLanguage,
        lines: lines,
      );
      if (trackId == null) {
        _setError('asrErrorGeneric');
        return;
      }

      // 5. Propagate detected language when it differs.
      await _maybeUpdateMediaLanguage(
        detected: result.language,
        persistedLanguage: trackLanguage,
      );

      if (cancel.isCompleted) {
        _setCancelled();
        return;
      }

      state = AsyncValue.data(
        AsrGenerationJob(
          mediaId: mediaId,
          language: trackLanguage,
          phase: AsrGenerationPhase.success,
          detectedLanguage: result.language,
          progress: 1.0,
          startedAt: startedAt,
          completedAt: DateTime.now(),
          trackId: trackId,
        ),
      );
    } finally {
      // 5. Free audio bytes eagerly.
      audio = null;
    }
  }

  Future<int> _resolveMediaDurationMs(String? mediaSourceUri) async {
    if (mediaSourceUri == null || mediaSourceUri.isEmpty) return 0;
    final db = ref.read(appDatabaseProvider);
    final tt = await dexieTargetTypeForId(db, mediaId);
    if (tt == 'Video') {
      final video = await db.videoDao.getById(mediaId);
      if (video != null && video.durationSeconds > 0) {
        return video.durationSeconds * 1000;
      }
    }
    if (tt == 'Audio') {
      final a = await db.audioDao.getById(mediaId);
      if (a != null && a.durationSeconds > 0) return a.durationSeconds * 1000;
    }
    return 0;
  }

  Future<void> _maybeUpdateMediaLanguage({
    required String? detected,
    required String persistedLanguage,
  }) async {
    if (detected == null || detected.isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    final tt = await dexieTargetTypeForId(db, mediaId);
    if (tt == null) return;
    if (tt == 'Video') {
      final row = await db.videoDao.getById(mediaId);
      if (row == null || row.language == persistedLanguage) return;
      await db.videoDao.updateLanguage(id: mediaId, language: detected);
    } else if (tt == 'Audio') {
      final row = await db.audioDao.getById(mediaId);
      if (row == null || row.language == persistedLanguage) return;
      await db.audioDao.updateLanguage(id: mediaId, language: detected);
    }
  }

  void _setPhase(AsrGenerationPhase phase) {
    if (_cancelToken?.isCompleted ?? false) return;
    _updateJob((j) => j.copyWith(phase: phase));
  }

  void _setError(String messageKey) {
    state = AsyncValue.data(
      AsrGenerationJob(
        mediaId: mediaId,
        language: '',
        phase: AsrGenerationPhase.error,
        errorMessage: messageKey,
        completedAt: DateTime.now(),
      ),
    );
  }

  void _setCancelled() {
    state = AsyncValue.data(
      AsrGenerationJob(
        mediaId: mediaId,
        language: '',
        phase: AsrGenerationPhase.cancelled,
        completedAt: DateTime.now(),
      ),
    );
  }

  void _updateJob(AsrGenerationJob Function(AsrGenerationJob) update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(update(current));
  }

  String _mapProviderError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('credit')) return 'asrErrorCreditsExhausted';
    if (s.contains('socket') ||
        s.contains('timeout') ||
        s.contains('network')) {
      return 'asrErrorNetwork';
    }
    return 'asrErrorGeneric';
  }
}

/// Singleton extractor (cheap; no state).
@Riverpod(keepAlive: true)
AsrAudioExtractor asrAudioExtractor(Ref ref) => const AsrAudioExtractor();
