/// Lazy auto-translate job orchestration for a media item.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/app_language_catalog.dart';
import '../../../core/application/app_preferences_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/logging/log.dart';
import '../../../core/riverpod/async_value_x.dart';
import '../../../data/db/media_target_resolver.dart';
import '../../../data/db/app_database_provider.dart';
import '../../../data/subtitle/subtitle_markup_parser.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../ai/application/ai_services.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/auto_translate.dart';
import 'active_transcript_provider.dart';
import 'transcript_playback_highlight_provider.dart';
import 'transcript_repository_provider.dart';

part 'auto_translate_controller.g.dart';

final Logger _log = logNamed('auto_translate');

@Riverpod(keepAlive: true)
class AutoTranslateCtrl extends _$AutoTranslateCtrl {
  Future<void>? _schedulerLoop;
  var _cancelRequested = false;
  final _inFlight = <int>{};
  final _lineAttempts = <int, int>{};
  final _lineBackoffUntil = <int, DateTime>{};
  /// Line indexes that must call translate with `forceRefresh: true` once.
  final _forceRefreshLines = <int>{};
  /// Primary lines with empty plain text — never schedule translate for these.
  final _skippedEmptySource = <int>{};
  /// Consecutive transient (5xx/network) failures across the job.
  var _consecutiveServiceFailures = 0;
  DateTime? _circuitOpenUntil;

  Set<int> get _excludeFromPending => {
    ...state.failedLineIndexes,
    ..._skippedEmptySource,
  };

  @override
  AutoTranslateUiState build(String mediaId) {
    ref.listen(activeTranscriptIdProvider(mediaId), (prev, next) {
      final aiId = state.aiTranscriptId;
      if (aiId == null) return;
      if (state.status != AutoTranslateJobStatus.running &&
          state.status != AutoTranslateJobStatus.paused) {
        return;
      }
      if (prev?.value != next.value) {
        unawaited(_handlePrimaryChanged());
      }
    });

    ref.listen(secondaryTranscriptIdProvider(mediaId), (prev, next) {
      final aiId = state.aiTranscriptId;
      if (aiId == null) return;
      final secondary = next.value;
      if (secondary != aiId &&
          (state.status == AutoTranslateJobStatus.running ||
              state.status == AutoTranslateJobStatus.paused)) {
        pause();
      }
    });

    ref.listen(transcriptPlaybackHighlightProvider(mediaId), (prev, next) {
      if (state.status != AutoTranslateJobStatus.running) return;
      if (prev != next) {
        state = state.copyWith(priorityAnchorIndex: next);
      }
    });

    unawaited(_hydrateIfAiSecondaryActive());
    return const AutoTranslateUiState();
  }

  Future<void> _hydrateIfAiSecondaryActive() async {
    final secondaryId = ref
        .read(secondaryTranscriptIdProvider(mediaId))
        .value;
    if (secondaryId == null) return;

    final repo = ref.read(transcriptRepositoryProvider);
    final row = await repo.transcriptRowById(secondaryId);
    if (row == null || row.source != 'ai') return;

    final primaryId = ref.read(activeTranscriptIdProvider(mediaId)).value;
    final aiLines = repo.linesForRow(row);
    final pending = pendingLineIndexes(aiLines, exclude: _excludeFromPending);
    final ready = readyLineCount(aiLines);
    final anchor = ref.read(transcriptPlaybackHighlightProvider(mediaId));

    if (!ref.mounted) return;
    state = state.copyWith(
      aiTranscriptId: row.id,
      primaryTranscriptId: primaryId,
      targetLanguage: row.language,
      pendingCount: pending.length,
      readyCount: ready,
      failedCount: state.failedLineIndexes.length,
      priorityAnchorIndex: anchor,
      status: pending.isEmpty
          ? (state.failedLineIndexes.isEmpty
                ? AutoTranslateJobStatus.completed
                : AutoTranslateJobStatus.paused)
          : AutoTranslateJobStatus.paused,
    );
  }

  Future<void> selectAutoTranslate() async {
    if (_schedulerLoop != null) {
      await _schedulerLoop;
    }

    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.signedOut,
      );
      return;
    }

    final native =
        ref.read(appPreferencesCtrlProvider).valueOrNull?.effectiveNativeLanguage;
    if (native == null || native.isEmpty) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final repo = ref.read(transcriptRepositoryProvider);
    final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
    if (primaryRow == null) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final primaryLines = repo.linesForRow(primaryRow);
    if (primaryLines.isEmpty) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final sourceBase = workerLanguageBase(primaryRow.language);
    final targetBase = workerLanguageBase(native);
    if (sourceBase == targetBase) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.sameLanguage,
      );
      return;
    }

    final aiId = await repo.ensureAutoTranslateTrack(
      mediaId: mediaId,
      primaryTranscriptId: primaryRow.id,
      targetLanguage: native,
      primaryLines: primaryLines,
    );
    if (aiId == null) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    await repo.setSecondaryTranscript(mediaId, aiId);

    final refreshedAi = await repo.transcriptRowById(aiId);
    final aiLines = refreshedAi == null
        ? buildAutoTranslateSkeleton(primaryLines)
        : repo.linesForRow(refreshedAi);
    // Keep previously failed indexes that still have empty text; drop ones
    // that somehow gained text (shouldn't happen, but keeps state consistent).
    final priorFailed = state.failedLineIndexes
        .where((i) => i >= 0 && i < aiLines.length && aiLines[i].text.trim().isEmpty)
        .toSet();
    _skippedEmptySource.clear();
    final pending = pendingLineIndexes(
      aiLines,
      exclude: {...priorFailed, ..._skippedEmptySource},
    );
    final ready = readyLineCount(aiLines);
    final anchor = ref.read(transcriptPlaybackHighlightProvider(mediaId));

    _lineAttempts.clear();
    _lineBackoffUntil.clear();
    _consecutiveServiceFailures = 0;
    _circuitOpenUntil = null;
    _cancelRequested = false;

    if (!ref.mounted) return;
    state = state.copyWith(
      status: pending.isEmpty
          ? (priorFailed.isEmpty
                ? AutoTranslateJobStatus.completed
                : AutoTranslateJobStatus.paused)
          : AutoTranslateJobStatus.running,
      clearBlockReason: true,
      aiTranscriptId: aiId,
      primaryTranscriptId: primaryRow.id,
      targetLanguage: native,
      pendingCount: pending.length,
      readyCount: ready,
      failedCount: priorFailed.length,
      failedLineIndexes: priorFailed,
      priorityAnchorIndex: anchor,
    );

    if (pending.isNotEmpty) {
      _startSchedulerLoop();
    }
  }

  void pause() {
    _cancelRequested = true;
    if (state.status == AutoTranslateJobStatus.running) {
      state = state.copyWith(status: AutoTranslateJobStatus.paused);
    }
  }

  /// Re-translates a single cue (force-refresh). Preserves all other lines.
  /// Also clears a prior failure for that line so it can be scheduled again.
  Future<void> retranslateLine(int lineIndex) async {
    final aiId = state.aiTranscriptId;
    final primaryId = state.primaryTranscriptId;
    if (aiId == null || primaryId == null) return;
    if (lineIndex < 0) return;

    final repo = ref.read(transcriptRepositoryProvider);
    final primaryRow = await repo.transcriptRowById(primaryId);
    if (primaryRow == null) return;
    final primaryLines = repo.linesForRow(primaryRow);
    if (lineIndex >= primaryLines.length) return;

    // Clear this line so the pending placeholder shows while refreshing.
    await repo.updateAutoTranslateLineText(
      aiTranscriptId: aiId,
      lineIndex: lineIndex,
      text: '',
    );
    _lineAttempts.remove(lineIndex);
    _lineBackoffUntil.remove(lineIndex);
    _forceRefreshLines.add(lineIndex);
    _consecutiveServiceFailures = 0;
    _circuitOpenUntil = null;

    if (!ref.mounted) return;
    final nextFailed = Set<int>.from(state.failedLineIndexes)..remove(lineIndex);
    final aiRow = await repo.transcriptRowById(aiId);
    final aiLines = aiRow == null
        ? buildAutoTranslateSkeleton(primaryLines)
        : repo.linesForRow(aiRow);
    _skippedEmptySource.remove(lineIndex);
    state = state.copyWith(
      status: AutoTranslateJobStatus.running,
      clearBlockReason: true,
      pendingCount: pendingLineIndexes(
        aiLines,
        exclude: {...nextFailed, ..._skippedEmptySource},
      ).length,
      readyCount: readyLineCount(aiLines),
      failedCount: nextFailed.length,
      failedLineIndexes: nextFailed,
    );

    _cancelRequested = false;
    if (_schedulerLoop == null) {
      _startSchedulerLoop();
    }
  }

  Future<void> retryAfterBlock() async {
    _consecutiveServiceFailures = 0;
    _circuitOpenUntil = null;
    // Clear exhausted failures so the job can try remaining empty lines again.
    if (state.failedLineIndexes.isNotEmpty) {
      state = state.copyWith(
        failedLineIndexes: const {},
        failedCount: 0,
        clearBlockReason: true,
      );
    }
    await selectAutoTranslate();
  }

  Future<void> _handlePrimaryChanged() async {
    final aiId = state.aiTranscriptId;
    if (aiId == null) return;

    pause();
    if (_schedulerLoop != null) {
      await _schedulerLoop;
    }

    final repo = ref.read(transcriptRepositoryProvider);
    final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
    if (primaryRow == null) {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final primaryLines = repo.linesForRow(primaryRow);
    final native = state.targetLanguage;
    if (native == null) return;

    await repo.ensureAutoTranslateTrack(
      mediaId: mediaId,
      primaryTranscriptId: primaryRow.id,
      targetLanguage: native,
      primaryLines: primaryLines,
    );
    await repo.setSecondaryTranscript(mediaId, aiId);

    _lineAttempts.clear();
    _lineBackoffUntil.clear();
    _skippedEmptySource.clear();
    _consecutiveServiceFailures = 0;
    _circuitOpenUntil = null;
    _cancelRequested = false;

    if (!ref.mounted) return;
    state = state.copyWith(
      primaryTranscriptId: primaryRow.id,
      pendingCount: primaryLines.length,
      readyCount: 0,
      failedCount: 0,
      failedLineIndexes: const {},
      status: AutoTranslateJobStatus.running,
      clearBlockReason: true,
    );
    _startSchedulerLoop();
  }

  void _startSchedulerLoop() {
    if (_schedulerLoop != null) return;
    final gen = state.generation;
    final future = _runScheduler(generation: gen);
    _schedulerLoop = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_schedulerLoop, future)) {
          _schedulerLoop = null;
        }
      }),
    );
  }

  Future<void> _runScheduler({required int generation}) async {
    final repo = ref.read(transcriptRepositoryProvider);
    final translator = ref.read(translationServiceProvider);

    while (!_cancelRequested && ref.mounted) {
      if (state.generation != generation) return;

      final circuitUntil = _circuitOpenUntil;
      if (circuitUntil != null) {
        final remaining = circuitUntil.difference(DateTime.now());
        if (remaining > Duration.zero) {
          state = state.copyWith(
            status: AutoTranslateJobStatus.blocked,
            blockReason: AutoTranslateBlockReason.serviceUnavailable,
          );
          _cancelRequested = true;
          return;
        }
        _circuitOpenUntil = null;
        _consecutiveServiceFailures = 0;
        if (state.blockReason == AutoTranslateBlockReason.serviceUnavailable) {
          state = state.copyWith(
            status: AutoTranslateJobStatus.running,
            clearBlockReason: true,
          );
        }
      }

      final aiId = state.aiTranscriptId;
      final primaryId = state.primaryTranscriptId;
      final targetLang = state.targetLanguage;
      if (aiId == null || primaryId == null || targetLang == null) return;

      final secondaryId = ref
          .read(secondaryTranscriptIdProvider(mediaId))
          .value;
      if (secondaryId != aiId) return;

      final primaryRow = await repo.transcriptRowById(primaryId);
      final aiRow = await repo.transcriptRowById(aiId);
      if (primaryRow == null || aiRow == null) return;

      final primaryLines = repo.linesForRow(primaryRow);
      final aiLines = repo.linesForRow(aiRow);

      if (repo.isAutoTranslateTrackStale(
        aiRow: aiRow,
        primaryId: primaryId,
        primaryLines: primaryLines,
      )) {
        state = state.copyWith(
          status: AutoTranslateJobStatus.blocked,
          blockReason: AutoTranslateBlockReason.stalePrimary,
        );
        return;
      }

      final failed = state.failedLineIndexes;
      final pending = pendingLineIndexes(aiLines, exclude: _excludeFromPending);
      if (pending.isEmpty) {
        state = state.copyWith(
          status: failed.isEmpty
              ? AutoTranslateJobStatus.completed
              : AutoTranslateJobStatus.paused,
          pendingCount: 0,
          readyCount: readyLineCount(aiLines),
          failedCount: failed.length,
        );
        return;
      }

      final anchor = ref.read(transcriptPlaybackHighlightProvider(mediaId));
      final ordered = orderPendingLineIndexes(
        anchorIndex: anchor >= 0 ? anchor : 0,
        pending: pending.where((i) => !_inFlight.contains(i)).toList(),
      );

      if (ordered.isEmpty && _inFlight.isEmpty) {
        // All remaining candidates are in backoff — wait for the soonest.
        final wait = _soonestBackoffWait(pending);
        await Future<void>.delayed(
          wait ?? const Duration(milliseconds: 200),
        );
        continue;
      }

      while (_inFlight.length < kAutoTranslateMaxConcurrency &&
          !_cancelRequested) {
        final candidates = orderPendingLineIndexes(
          anchorIndex: anchor >= 0 ? anchor : 0,
          pending: pending
              .where((i) => !_inFlight.contains(i))
              .toList(),
        );
        if (candidates.isEmpty) break;

        var started = false;
        for (final index in candidates) {
          if (_inFlight.length >= kAutoTranslateMaxConcurrency) break;
          if (_inFlight.contains(index)) continue;
          if (state.failedLineIndexes.contains(index)) continue;

          final backoff = _lineBackoffUntil[index];
          if (backoff != null && DateTime.now().isBefore(backoff)) {
            continue;
          }

          _inFlight.add(index);
          started = true;
          final forceRefresh = _forceRefreshLines.remove(index);
          unawaited(
            _translateLine(
              generation: generation,
              lineIndex: index,
              primaryLine: primaryLines[index],
              sourceLanguage: primaryRow.language,
              targetLanguage: targetLang,
              aiTranscriptId: aiId,
              translator: translator,
              forceRefresh: forceRefresh,
            ),
          );
        }
        if (!started) break;
      }

      state = state.copyWith(
        pendingCount: pending.length,
        readyCount: readyLineCount(aiLines),
        failedCount: state.failedLineIndexes.length,
        priorityAnchorIndex: anchor,
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  Duration? _soonestBackoffWait(List<int> pending) {
    DateTime? soonest;
    final now = DateTime.now();
    for (final i in pending) {
      final until = _lineBackoffUntil[i];
      if (until == null) continue;
      if (until.isAfter(now) && (soonest == null || until.isBefore(soonest))) {
        soonest = until;
      }
    }
    if (soonest == null) return null;
    final wait = soonest.difference(now);
    if (wait <= Duration.zero) return null;
    // Cap so the loop stays responsive to pause/cancel.
    return wait > const Duration(seconds: 5) ? const Duration(seconds: 5) : wait;
  }

  Future<void> _translateLine({
    required int generation,
    required int lineIndex,
    required TranscriptLine primaryLine,
    required String sourceLanguage,
    required String targetLanguage,
    required String aiTranscriptId,
    required TranslationService translator,
    required bool forceRefresh,
  }) async {
    try {
      if (state.generation != generation) return;

      final plain = plainTextFromSubtitleMarkup(primaryLine.text).trim();
      if (plain.isEmpty) {
        // Nothing to translate — permanently skip (do not retry forever).
        _skippedEmptySource.add(lineIndex);
        _lineAttempts.remove(lineIndex);
        _lineBackoffUntil.remove(lineIndex);
        return;
      }

      final result = await translator.translate(
        text: plain,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        forceRefresh: forceRefresh,
      );

      if (state.generation != generation) return;

      await ref.read(transcriptRepositoryProvider).updateAutoTranslateLineText(
        aiTranscriptId: aiTranscriptId,
        lineIndex: lineIndex,
        text: result.translatedText,
      );
      _lineAttempts.remove(lineIndex);
      _lineBackoffUntil.remove(lineIndex);
      _consecutiveServiceFailures = 0;
    } on AuthFailure {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.auth,
      );
      _cancelRequested = true;
    } on CreditsFailure {
      state = state.copyWith(
        status: AutoTranslateJobStatus.blocked,
        blockReason: AutoTranslateBlockReason.credits,
      );
      _cancelRequested = true;
    } catch (e, st) {
      final attempts = (_lineAttempts[lineIndex] ?? 0) + 1;
      _lineAttempts[lineIndex] = attempts;
      final isService = _isTransientServiceFailure(e);
      if (isService) {
        _consecutiveServiceFailures++;
      }

      if (attempts >= kAutoTranslateMaxLineRetries) {
        final nextFailed = Set<int>.from(state.failedLineIndexes)..add(lineIndex);
        _lineBackoffUntil.remove(lineIndex);
        _log.warning(
          'auto-translate line $lineIndex exhausted retries '
          '($kAutoTranslateMaxLineRetries): $e',
        );
        state = state.copyWith(
          failedCount: nextFailed.length,
          failedLineIndexes: nextFailed,
        );
      } else {
        final delay = kAutoTranslateRetryBaseDelay * (1 << (attempts - 1));
        _lineBackoffUntil[lineIndex] = DateTime.now().add(delay);
        _log.warning(
          'auto-translate line $lineIndex failed '
          '(attempt $attempts/$kAutoTranslateMaxLineRetries, '
          'retry in ${delay.inSeconds}s): $e',
        );
        // Avoid dumping full stacks on every transient 500.
        if (!isService) {
          _log.fine('auto-translate line $lineIndex stack', e, st);
        }
      }

      if (_consecutiveServiceFailures >= kAutoTranslateCircuitBreakerThreshold) {
        _circuitOpenUntil = DateTime.now().add(
          kAutoTranslateCircuitBreakerCooldown,
        );
        _log.warning(
          'auto-translate circuit open for '
          '${kAutoTranslateCircuitBreakerCooldown.inSeconds}s after '
          '$_consecutiveServiceFailures consecutive service failures',
        );
        state = state.copyWith(
          status: AutoTranslateJobStatus.blocked,
          blockReason: AutoTranslateBlockReason.serviceUnavailable,
        );
        _cancelRequested = true;
      }
    } finally {
      _inFlight.remove(lineIndex);
    }
  }

  bool _isTransientServiceFailure(Object e) {
    if (e is NetworkFailure) {
      final code = e.statusCode;
      return code == null || code >= 500 || code == 429;
    }
    return false;
  }
}

/// Whether [secondaryId] is the auto-translate AI track for [mediaId].
@riverpod
Future<bool> isAutoTranslateSecondary(
  Ref ref,
  String mediaId,
  String? secondaryId,
) async {
  if (secondaryId == null) return false;
  final row = await ref
      .read(transcriptRepositoryProvider)
      .transcriptRowById(secondaryId);
  return row?.source == 'ai';
}

/// Predicted AI track id for picker radio value (may not exist in DB yet).
@riverpod
Future<String?> autoTranslateSelectionId(Ref ref, String mediaId) async {
  final auth = ref.watch(authCtrlProvider).valueOrNull;
  if (auth is! AuthSignedIn) return null;
  final native = ref
      .watch(appPreferencesCtrlProvider)
      .valueOrNull
      ?.effectiveNativeLanguage;
  if (native == null || native.isEmpty) return null;

  final db = ref.read(appDatabaseProvider);
  final tt = await dexieTargetTypeForId(db, mediaId);
  if (tt == null) return null;

  return autoTranslateAiTrackId(
    targetType: tt,
    mediaId: mediaId,
    targetLanguage: native,
  );
}
