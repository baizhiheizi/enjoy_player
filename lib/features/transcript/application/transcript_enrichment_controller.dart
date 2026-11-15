/// The Riverpod surface of the explicit CC-sheet enrich.
library;

import 'package:forced_alignment/forced_alignment.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enricher.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_state.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/forced_alignment_enrichment_backend.dart';

export 'transcript_enricher.dart';
export 'transcript_enrichment_state.dart';

part 'transcript_enrichment_controller.g.dart';

@Riverpod(keepAlive: true)
TranscriptEnricher transcriptEnricher(Ref ref) {
  final repo = ref.watch(transcriptRepositoryProvider);
  return TranscriptEnricher(
    replaceTimeline: ({required transcriptId, required lines}) {
      return repo.replaceTimeline(transcriptId: transcriptId, lines: lines);
    },
    backend: const ForcedAlignmentEnrichmentBackend(),
  );
}

@riverpod
class TranscriptEnrichmentController extends _$TranscriptEnrichmentController {
  AlignmentCancelToken? _cancel;
  var _runId = 0;

  @override
  TranscriptEnrichmentState build(String mediaId) {
    return const TranscriptEnrichmentState.idle();
  }

  /// Starts enrich for the current primary track. Opening the sheet / play /
  /// seek must not call this.
  Future<void> run() async {
    if (state.isRunning) return;
    _cancel?.cancel();
    final token = AlignmentCancelToken();
    _cancel = token;
    final id = ++_runId;
    state = const TranscriptEnrichmentState.running();

    try {
      final repo = ref.read(transcriptRepositoryProvider);
      final row = await repo.primaryTranscriptRowForMedia(mediaId);
      if (!ref.mounted || id != _runId) return;
      if (row == null) {
        state = const TranscriptEnrichmentState.failed('noPrimary');
        return;
      }
      final lines = repo.linesForRow(row);
      if (lines.isEmpty) {
        state = const TranscriptEnrichmentState.failed('empty');
        return;
      }

      final db = ref.read(appDatabaseProvider);
      final source = await resolvePlayableSource(db, mediaId);
      if (!ref.mounted || id != _runId) return;
      final extractable =
          source is LocalFilePlayableSource ||
          source is RemoteUrlPlayableSource;
      final localPath = switch (source) {
        LocalFilePlayableSource(:final uri) => uri,
        RemoteUrlPlayableSource(:final uri) => uri,
        _ => null,
      };

      state = TranscriptEnrichmentState.running(total: lines.length);
      final outcome = await ref
          .read(transcriptEnricherProvider)
          .enrich(
            transcriptId: row.id,
            lines: lines,
            language: row.language,
            extractable: extractable,
            localPath: localPath,
            cancel: token,
            onProgress: ({required completed, required total}) {
              if (!ref.mounted || id != _runId) return;
              state = TranscriptEnrichmentState.running(
                completed: completed,
                total: total,
              );
            },
          );
      if (!ref.mounted || id != _runId) return;
      if (token.isCancelled) {
        state = const TranscriptEnrichmentState.failed('cancelled');
        return;
      }
      switch (outcome) {
        case TranscriptEnrichmentOk():
          state = const TranscriptEnrichmentState.succeeded();
        case TranscriptEnrichmentErr(:final reason):
          logNamed('transcript.enrichment').warning('run failed: $reason');
          state = TranscriptEnrichmentState.failed(reason);
      }
    } on Object catch (e, st) {
      logNamed('transcript.enrichment').warning('run failed: $e', e, st);
      if (!ref.mounted || id != _runId) return;
      state = const TranscriptEnrichmentState.failed('internal');
    }
  }

  void cancel() {
    _cancel?.cancel();
    _runId++;
    if (state.isRunning) {
      state = const TranscriptEnrichmentState.failed('cancelled');
    }
  }
}
