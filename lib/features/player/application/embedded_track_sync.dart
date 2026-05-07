/// One-shot subscription to embedded subtitle tracks after open.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;

import '../../../data/db/app_database_provider.dart';
import '../../../data/subtitle/embedded_subtitle_service.dart';
import '../../transcript/application/transcript_repository_provider.dart';
import 'embedded_tracks_notifier.dart';
import 'player_engine_provider.dart';

class EmbeddedTrackSync {
  EmbeddedTrackSync(this._ref);

  final Ref _ref;
  StreamSubscription<mk.Tracks>? _sub;

  Future<void> startForMedia({
    required String mediaId,
    required String sourceUri,
  }) async {
    await _sub?.cancel();
    _sub = null;

    final engine = _ref.read(playerEngineProvider);
    _sub = engine.tracks
        .where((t) => t.subtitle.isNotEmpty)
        .take(1)
        .listen((tracks) async {
          final db = _ref.read(appDatabaseProvider);
          final existing = await db.transcriptDao.listForMedia(mediaId);
          final existingIndices =
              existing
                  .where((r) => r.isEmbedded && r.trackIndex != null)
                  .map((r) => r.trackIndex!)
                  .toSet();

          final extracted = await const EmbeddedSubtitleService().extractTracks(
            mediaId: mediaId,
            mediaSourceUri: sourceUri,
            tracks: tracks.subtitle,
            existingTrackIndices: existingIndices,
          );

          if (extracted.isEmpty) return;

          final repo = _ref.read(transcriptRepositoryProvider);
          await repo.upsertEmbeddedTracks(extracted);

          final session = await db.sessionDao.getForMedia(mediaId);
          if (session?.primaryTranscriptId == null) {
            await db.sessionDao.updatePrimaryTranscript(
              mediaId,
              extracted.first.id,
            );
          }

          _ref
              .read(embeddedTracksProvider.notifier)
              .notifyFound(mediaId, extracted.length);
        });
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    unawaited(cancel());
  }
}

final embeddedTrackSyncProvider = Provider<EmbeddedTrackSync>((ref) {
  final s = EmbeddedTrackSync(ref);
  ref.onDispose(s.dispose);
  return s;
});
