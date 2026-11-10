/// On-demand per-line auto-translate for a media item's AI secondary track.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/application/app_language_catalog.dart';
import '../../../core/application/app_preferences_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/logging/log.dart';
import '../../../core/riverpod/async_value_x.dart';
import '../../../data/subtitle/subtitle_markup_parser.dart';
import '../../ai/application/ai_services.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/auto_translate.dart';
import 'active_transcript_provider.dart';
import 'auto_translate_line_queue.dart';
import 'transcript_playback_highlight_provider.dart';
import 'transcript_repository_provider.dart';

part 'auto_translate_controller.g.dart';

final Logger _log = logNamed('auto_translate');

@riverpod
class AutoTranslateCtrl extends _$AutoTranslateCtrl {
  var _hydrateRunId = 0;
  final _flushHookRepos = <TranscriptRepository>[];

  late final AutoTranslateLineQueue _queue = AutoTranslateLineQueue(
    isLineFailed: (lineIndex) => state.isLineFailed(lineIndex),
    startTranslate: (lineIndex, {required bool forceRefresh}) =>
        unawaited(_translateLine(lineIndex, forceRefresh: forceRefresh)),
    currentCueAnchor: () =>
        ref.read(transcriptPlaybackHighlightProvider(mediaId)).cueIndex,
    publishInFlight: (inFlightIndexes) {
      if (!ref.mounted) return;
      state = state.copyWith(inFlightIndexes: inFlightIndexes);
    },
  );

  /// Repository access for this controller. Every distinct instance read
  /// here is registered for the disposal flush of its pending writes (issue
  /// #810 D1): the write buffer lives per repository, and the auth-scoped
  /// database can swap the provider's instance under a live controller.
  /// Kept out of [build] on purpose: the repository depends on the
  /// auth-scoped database, which is unavailable while signed out, and the
  /// transcript chrome builds this controller regardless of auth.
  TranscriptRepository _repo() {
    final repo = ref.read(transcriptRepositoryProvider);
    if (_flushHookRepos.isEmpty) {
      ref.onDispose(_flushRegisteredRepos);
    }
    if (!_flushHookRepos.contains(repo)) {
      _flushHookRepos.add(repo);
    }
    return repo;
  }

  void _flushRegisteredRepos() {
    for (final repo in _flushHookRepos) {
      unawaited(
        repo.flushAutoTranslateWrites().catchError((Object e, StackTrace st) {
          _log.warning('auto-translate dispose flush failed', e, st);
        }),
      );
    }
  }

  @override
  AutoTranslateUiState build(String mediaId) {
    _hydrateRunId++;
    ref.listen(activeTranscriptIdProvider(mediaId), (prev, next) {
      if (state.aiTranscriptId == null) return;
      if (state.status != AutoTranslateStatus.active) return;
      if (prev?.value != next.value) {
        unawaited(_handlePrimaryChanged());
      }
    });

    ref.listen(secondaryTranscriptIdProvider(mediaId), (prev, next) {
      if (state.aiTranscriptId == null &&
          next.value != null &&
          next.value != prev?.value) {
        unawaited(_hydrateIfAiSecondaryActive(secondaryId: next.value));
      }
      final aiId = state.aiTranscriptId;
      if (aiId == null) return;
      if (next.value != aiId && state.status == AutoTranslateStatus.active) {
        _clearInFlightTracking();
        state = state.copyWith(status: AutoTranslateStatus.idle);
      }
    });

    ref.listen(
      transcriptPlaybackHighlightProvider(mediaId).select((h) => h.cueIndex),
      (prev, next) {
        if (prev == next) return;
        if (state.status != AutoTranslateStatus.active) return;
        _queue.reprioritize(anchor: next);
      },
    );

    unawaited(_hydrateIfAiSecondaryActive());
    return const AutoTranslateUiState();
  }

  /// Only the latest hydration run may write [state] — a secondary-id flip
  /// while an older run is between awaits must not clobber the newer run's
  /// write with stale row reads. [secondaryId] pins the trigger's id so the
  /// row fetch cannot drift to a newer provider value mid-flight.
  Future<void> _hydrateIfAiSecondaryActive({String? secondaryId}) async {
    final runId = ++_hydrateRunId;
    final id =
        secondaryId ?? ref.read(secondaryTranscriptIdProvider(mediaId)).value;
    if (id == null) return;

    final repo = _repo();
    final row = await repo.transcriptRowById(id);
    if (!ref.mounted || runId != _hydrateRunId) return;
    if (row == null || row.source != 'ai') return;

    final primaryId = ref.read(activeTranscriptIdProvider(mediaId)).value;
    String? sourceLanguage;
    if (primaryId != null) {
      final primaryRow = await repo.transcriptRowById(primaryId);
      sourceLanguage = primaryRow?.language;
    }
    if (!ref.mounted || runId != _hydrateRunId) return;
    state = state.copyWith(
      status: AutoTranslateStatus.active,
      clearBlockReason: true,
      aiTranscriptId: row.id,
      primaryTranscriptId: primaryId,
      sourceLanguage: sourceLanguage,
      targetLanguage: row.language,
    );
  }

  /// Ensures the AI track exists and sets it as secondary. Does not translate
  /// lines — the transcript list requests each line when it enters the viewport.
  Future<void> selectAutoTranslate() async {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) {
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.signedOut,
      );
      return;
    }

    final native = ref
        .read(appPreferencesCtrlProvider)
        .valueOrNull
        ?.effectiveNativeLanguage;
    if (native == null || native.isEmpty) {
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final repo = _repo();
    final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
    if (primaryRow == null) {
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final primaryLines = repo.linesForRow(primaryRow);
    if (primaryLines.isEmpty) {
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final sourceBase = workerLanguageBase(primaryRow.language);
    final targetBase = workerLanguageBase(native);
    if (sourceBase == targetBase) {
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
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
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    await repo.setSecondaryTranscript(mediaId, aiId);
    if (!ref.mounted) return;

    _queue.clearWaiting();
    _hydrateRunId++;
    state = state.copyWith(
      status: AutoTranslateStatus.active,
      clearBlockReason: true,
      aiTranscriptId: aiId,
      primaryTranscriptId: primaryRow.id,
      sourceLanguage: primaryRow.language,
      targetLanguage: native,
      failedLineIndexes: state.failedLineIndexes
          .where((i) => i >= 0 && i < primaryLines.length)
          .toSet(),
    );
    ref
        .read(analyticsProvider)
        .capture(
          AnalyticsEvents.translationRequested,
          properties: AnalyticsEvents.translationRequestedProps(
            kind: AnalyticsEvents.kindStandard,
            cacheHit: false,
          ),
        );
  }

  /// Requests translation for a single cue when it becomes visible.
  /// Idempotent: no-op if cached, in-flight, failed, or Auto translate inactive.
  void requestTranslateLine(int lineIndex) {
    if (lineIndex < 0) return;
    if (state.status != AutoTranslateStatus.active) return;
    if (state.aiTranscriptId == null ||
        state.primaryTranscriptId == null ||
        state.targetLanguage == null) {
      return;
    }
    if (state.isLineFailed(lineIndex)) return;
    if (_queue.isInFlight(lineIndex) || state.isLineInFlight(lineIndex)) {
      return;
    }
    if (_queue.isWaiting(lineIndex)) return;

    final secondaryId = ref.read(secondaryTranscriptIdProvider(mediaId)).value;
    if (secondaryId != null && secondaryId != state.aiTranscriptId) return;

    if (!_queue.hasFreeSlot) {
      _enqueueWaiting(lineIndex);
      return;
    }

    unawaited(_translateLine(lineIndex, forceRefresh: false));
  }

  /// Re-translates a single cue (force-refresh). Preserves all other lines.
  Future<void> retranslateLine(int lineIndex) async {
    final aiId = state.aiTranscriptId;
    final primaryId = state.primaryTranscriptId;
    if (aiId == null || primaryId == null) return;
    if (lineIndex < 0) return;
    if (state.status != AutoTranslateStatus.active) return;

    final repo = _repo();
    final primary = await repo.contentById(primaryId);
    if (primary == null) return;
    final primaryLines = primary.lines;
    if (lineIndex >= primaryLines.length) return;

    await repo.updateAutoTranslateLineText(
      aiTranscriptId: aiId,
      lineIndex: lineIndex,
      text: '',
    );
    if (!ref.mounted) return;

    final nextFailed = Set<int>.from(state.failedLineIndexes)
      ..remove(lineIndex);
    _queue.removeWaiting(lineIndex);
    _queue.markForceRefresh(lineIndex);
    state = state.copyWith(failedLineIndexes: nextFailed);

    if (_queue.isInFlight(lineIndex)) return;
    if (!_queue.hasFreeSlot) {
      _enqueueWaiting(lineIndex, preferFront: true);
      return;
    }
    unawaited(_translateLine(lineIndex, forceRefresh: true));
  }

  Future<void> _handlePrimaryChanged() async {
    final aiId = state.aiTranscriptId;
    final native = state.targetLanguage;
    if (aiId == null || native == null) return;

    final repo = _repo();
    final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
    if (primaryRow == null) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: AutoTranslateStatus.blocked,
        blockReason: AutoTranslateBlockReason.noPrimary,
      );
      return;
    }

    final primaryLines = repo.linesForRow(primaryRow);
    await repo.ensureAutoTranslateTrack(
      mediaId: mediaId,
      primaryTranscriptId: primaryRow.id,
      targetLanguage: native,
      primaryLines: primaryLines,
    );
    await repo.setSecondaryTranscript(mediaId, aiId);
    if (!ref.mounted) return;

    _clearInFlightTracking();
    _hydrateRunId++;
    state = state.copyWith(
      status: AutoTranslateStatus.active,
      clearBlockReason: true,
      primaryTranscriptId: primaryRow.id,
      sourceLanguage: primaryRow.language,
      failedLineIndexes: const {},
    );
  }

  Future<void> _translateLine(
    int lineIndex, {
    required bool forceRefresh,
  }) async {
    final aiId = state.aiTranscriptId;
    final primaryId = state.primaryTranscriptId;
    final targetLang = state.targetLanguage;
    if (aiId == null || primaryId == null || targetLang == null) return;

    _queue.markInFlight(lineIndex);
    try {
      for (
        var attempt = 1;
        attempt <= kAutoTranslateMaxLineAttempts;
        attempt++
      ) {
        if (!ref.mounted) return;
        if (state.status != AutoTranslateStatus.active) return;
        final secondaryNow = ref
            .read(secondaryTranscriptIdProvider(mediaId))
            .value;
        if (secondaryNow != null && secondaryNow != aiId) return;

        final repo = _repo();
        final primary = await repo.contentById(primaryId);
        final ai = await repo.contentById(aiId);
        if (primary == null || ai == null) return;
        final primaryLines = primary.lines;
        if (lineIndex >= primaryLines.length) return;

        if (repo.isAutoTranslateTrackStale(
          aiReferenceId: ai.referenceId,
          primaryId: primaryId,
          primaryLines: primaryLines,
          aiLines: ai.lines,
        )) {
          if (!ref.mounted) return;
          state = state.copyWith(
            status: AutoTranslateStatus.blocked,
            blockReason: AutoTranslateBlockReason.stalePrimary,
          );
          return;
        }

        final aiLines = ai.lines;
        final sourceLang = primary.language;
        final primaryLine = primaryLines[lineIndex];
        final plain = plainTextFromSubtitleMarkup(primaryLine.text).trim();
        if (plain.isEmpty) {
          return;
        }

        final sourceKey = autoTranslateSourceKey(
          primaryText: primaryLine.text,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final useForce = forceRefresh || _queue.consumeForceRefresh(lineIndex);
        if (!useForce) {
          final existing = resolveAutoTranslateSecondaryText(
            primaryLines: primaryLines,
            aiLines: aiLines,
            lineIndex: lineIndex,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
          );
          if (existing != null) return;

          final reused = findCachedAutoTranslateText(
            aiLines: aiLines,
            key: sourceKey,
          );
          if (reused != null) {
            await repo.updateAutoTranslateLineText(
              aiTranscriptId: aiId,
              lineIndex: lineIndex,
              text: reused,
              sourceKey: sourceKey,
            );
            return;
          }
        }

        try {
          final result = await ref
              .read(translationServiceProvider)
              .translate(
                text: plain,
                sourceLanguage: sourceLang,
                targetLanguage: targetLang,
                forceRefresh: useForce,
              );

          if (!ref.mounted) return;
          final secondaryAfter = ref
              .read(secondaryTranscriptIdProvider(mediaId))
              .value;
          if (secondaryAfter != null && secondaryAfter != aiId) return;

          await repo.updateAutoTranslateLineText(
            aiTranscriptId: aiId,
            lineIndex: lineIndex,
            text: result.translatedText,
            sourceKey: sourceKey,
          );
          return;
        } on AuthFailure {
          if (!ref.mounted) return;
          state = state.copyWith(
            status: AutoTranslateStatus.blocked,
            blockReason: AutoTranslateBlockReason.auth,
          );
          return;
        } on CreditsFailure catch (failure) {
          if (!ref.mounted) return;
          state = state.copyWith(
            status: AutoTranslateStatus.blocked,
            blockReason: AutoTranslateBlockReason.credits,
            creditsFailure: failure,
          );
          return;
        } catch (e, st) {
          if (attempt >= kAutoTranslateMaxLineAttempts) {
            _log.warning(
              'auto-translate line $lineIndex failed after '
              '$kAutoTranslateMaxLineAttempts attempts: $e',
            );
            if (!ref.mounted) return;
            final nextFailed = Set<int>.from(state.failedLineIndexes)
              ..add(lineIndex);
            state = state.copyWith(failedLineIndexes: nextFailed);
            return;
          }
          _log.warning(
            'auto-translate line $lineIndex attempt $attempt failed, retrying: $e',
          );
          _log.fine('auto-translate line $lineIndex stack', e, st);
        }
      }
    } finally {
      _queue.releaseInFlight(lineIndex);
      if (ref.mounted) {
        _queue.drain();
      }
    }
  }

  /// Queues [lineIndex] and reorders the waiting lines around the playback
  /// anchor, dropping the ones the user seeked away from.
  void _enqueueWaiting(int lineIndex, {bool preferFront = false}) {
    _queue.enqueue(lineIndex, preferFront: preferFront);
    _queue.reprioritize();
  }

  void _clearInFlightTracking() {
    _queue.clear();
  }
}
