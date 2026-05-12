/// Shared embedded-subtitle extraction for local video (sheet + empty state).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Demuxes embedded subtitle streams via ffmpeg / media_kit metadata.
Future<void> runEmbeddedSubtitleExtract({
  required BuildContext context,
  required WidgetRef ref,
  required String mediaId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final db = ref.read(appDatabaseProvider);
  final uri = await resolvePlayableSourceUri(db, mediaId);
  if (uri == null) {
    if (context.mounted) {
      AppNotice.error(context, l10n.subtitlesNoPlayableUri);
    }
    return;
  }

  final tracksStream = ref.read(playerEngineProvider).mkTracksStream;
  var playerSubs = <mk.SubtitleTrack>[];
  if (tracksStream != null) {
    try {
      final t = await tracksStream
          .firstWhere((e) => e.subtitle.isNotEmpty)
          .timeout(const Duration(seconds: 2));
      playerSubs = t.subtitle;
    } on TimeoutException {
      // media_kit may not list subtitles until metadata is ready — ffmpeg probe
      // in [TranscriptRepository.extractEmbeddedTracks] still runs.
    }
  }

  final count = await ref.read(transcriptRepositoryProvider).extractEmbeddedTracks(
        mediaId: mediaId,
        sourceUri: uri,
        playerSubtitleTracks: playerSubs,
      );

  if (!context.mounted) return;
  if (count == 0) {
    AppNotice.warning(context, l10n.subtitlesExtractNoTracks);
  } else {
    AppNotice.success(context, l10n.subtitlesExtractedCount(count));
  }
}
