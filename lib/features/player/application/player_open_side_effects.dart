/// Post-open work that is not required for immediate playback (transcripts, sync).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';

void schedulePlayerOpenSideEffects(
  Ref ref, {
  required int openGeneration,
  required bool Function() isStale,
  required String mediaId,
  required String dexieTargetType,
}) {
  final auth = ref.read(authCtrlProvider).valueOrNull;
  final signedIn = auth is AuthSignedIn;

  unawaited(
    _runTranscriptResolve(
      ref,
      mediaId: mediaId,
      isStale: isStale,
      signedIn: signedIn,
    ),
  );

  if (signedIn) {
    unawaited(
      _runRecordingPull(
        ref,
        dexieTargetType: dexieTargetType,
        mediaId: mediaId,
        isStale: isStale,
      ),
    );
  }
}

Future<void> _runTranscriptResolve(
  Ref ref, {
  required String mediaId,
  required bool Function() isStale,
  required bool signedIn,
}) async {
  if (isStale()) return;
  await ref
      .read(transcriptFetchCtrlProvider(mediaId).notifier)
      .resolveOnOpen(signedIn: signedIn);
}

Future<void> _runRecordingPull(
  Ref ref, {
  required String dexieTargetType,
  required String mediaId,
  required bool Function() isStale,
}) async {
  if (isStale()) return;
  await ref.read(recordingTargetSyncServiceProvider).pullRecordingsForTarget(
    targetType: dexieTargetType,
    targetId: mediaId,
  );
}

/// Lazy oEmbed retry after YouTube WebView reports playback-ready.
void scheduleYoutubeMetadataRefresh(
  Ref ref, {
  required String mediaId,
  required int openGeneration,
}) {
  unawaited(
    _runYoutubeMetadataRefresh(
      ref,
      mediaId: mediaId,
      openGeneration: openGeneration,
    ),
  );
}

Future<void> _runYoutubeMetadataRefresh(
  Ref ref, {
  required String mediaId,
  required int openGeneration,
}) async {
  final row = await ref.read(appDatabaseProvider).videoDao.getById(mediaId);
  if (row == null || row.provider.toLowerCase() != 'youtube') return;
  if (!_youtubeMetadataNeedsRefresh(row)) return;

  final controller = ref.read(playerControllerProvider.notifier);
  final engine = controller.engine;

  final ready = Completer<void>();
  StreamSubscription<bool>? bufferingSub;
  StreamSubscription<Duration>? durationSub;
  Timer? timeout;

  void finish() {
    if (!ready.isCompleted) ready.complete();
  }

  timeout = Timer(const Duration(seconds: 5), finish);
  bufferingSub = engine.buffering.listen((buffering) {
    if (!buffering) finish();
  });
  durationSub = engine.duration.listen((duration) {
    if (duration > Duration.zero) finish();
  });

  await ready.future;
  await bufferingSub.cancel();
  await durationSub.cancel();
  timeout.cancel();

  if (controller.openGeneration != openGeneration) return;
  if (ref.read(playerControllerProvider)?.mediaId != mediaId) return;

  final patch = await ref
      .read(mediaLibraryRepositoryProvider)
      .refreshYoutubeMetadataIfNeeded(mediaId);
  if (patch == null) return;

  controller.patchSessionMetadataIfCurrent(
    mediaId: mediaId,
    openGeneration: openGeneration,
    title: patch.title,
    thumbnailUrl: patch.thumbnailUrl,
  );
}

bool _youtubeMetadataNeedsRefresh(VideoRow row) {
  return isYoutubeImportPlaceholderTitle(row.title, row.vid) ||
      row.thumbnailUrl == null ||
      row.thumbnailUrl!.trim().isEmpty;
}
