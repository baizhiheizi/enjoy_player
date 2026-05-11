/// Loads library rows + [PlayableSource] for opening media in the player.
library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

/// Successful resolution of a media id to rows + playable URI/source.
class PlaybackOpenResolved {
  const PlaybackOpenResolved({
    required this.mediaId,
    required this.video,
    required this.audio,
    required this.kind,
    required this.playable,
    required this.title,
    required this.thumbnailUrl,
    required this.language,
    required this.durationSeconds,
  });

  final String mediaId;
  final VideoRow? video;
  final AudioRow? audio;
  final MediaKind kind;
  final PlayableSource playable;
  final String title;
  final String? thumbnailUrl;
  final String language;
  final int durationSeconds;

  String get dexieTargetType => kind.dexieTargetType;
}

/// Loads [VideoRow]/[AudioRow] and [resolvePlayableSource].
///
/// Returns `null` when the id is missing or has no playable source and no
/// relocate fingerprint. Throws [MediaNeedsRelocateException] when a hash is
/// present but the file cannot be resolved.
Future<PlaybackOpenResolved?> resolvePlaybackOpen(
  AppDatabase db,
  String mediaId,
) async {
  final video = await db.videoDao.getById(mediaId);
  final audio = video == null ? await db.audioDao.getById(mediaId) : null;
  if (video == null && audio == null) return null;

  final kind = video != null ? MediaKind.video : MediaKind.audio;
  final title = video?.title ?? audio!.title;

  final playable = await resolvePlayableSource(db, mediaId);
  if (playable == null) {
    final fingerprint = video?.md5 ?? audio?.md5;
    if (fingerprint != null && fingerprint.isNotEmpty) {
      throw MediaNeedsRelocateException(
        mediaId: mediaId,
        kind: kind,
        title: title,
        expectedHash: fingerprint,
        expectedSize: video?.size ?? audio?.size,
      );
    }
    return null;
  }

  final thumb = video != null ? video.thumbnailUrl : audio!.thumbnailUrl;
  final language = video != null ? video.language : audio!.language;
  final durationSec = video != null ? video.durationSeconds : audio!.durationSeconds;

  return PlaybackOpenResolved(
    mediaId: mediaId,
    video: video,
    audio: audio,
    kind: kind,
    playable: playable,
    title: title,
    thumbnailUrl: thumb,
    language: language,
    durationSeconds: durationSec,
  );
}
