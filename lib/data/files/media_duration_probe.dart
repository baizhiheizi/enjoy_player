/// FFmpeg duration probe that patches a media row's `duration_seconds`.
///
/// Shared by the library import path and the Craft persistence module so
/// the isolate hop and the zero-duration guard live in one place.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';

/// Fills `duration_seconds` when still zero after import, using `ffmpeg -i`.
///
/// The probe is dispatched to a worker isolate so a multi-GB video
/// import does not block the UI thread for several seconds. The
/// Isolate.run pattern mirrors `lib/data/files/file_storage.dart:128`
/// (chunked SHA-256 hashing) so the platform-channel hop is amortised
/// across the import.
///
/// The persist step crosses [MediaRegistry.patchDurationIfZero] — the
/// shared write-after-read that also serves the engine duration listener —
/// so the caller no longer needs to know which table holds [mediaId].
Future<void> probeAndPatchMediaDuration(
  AppDatabase db,
  String mediaId,
  String fileUri,
) async {
  final ffmpeg = await FfmpegMediaProbe.resolveFfmpegExecutable();
  if (ffmpeg == null) return;
  final input = FfmpegMediaProbe.mediaInputForFfmpeg(fileUri);

  Duration? sec;
  try {
    sec = await Isolate.run(
      () => _probeDurationInIsolate(ffmpeg, input),
      debugName: 'ffmpeg-duration-probe',
    );
  } catch (_) {
    return;
  }
  if (sec == null) return;

  await MediaRegistry(db).patchDurationIfZero(mediaId, sec.inSeconds);
}

/// Top-level so it can be sent to a worker isolate via [Isolate.run].
/// Returns the parsed duration in seconds, or `null` when ffmpeg is
/// missing / the input is unreadable / the stderr does not contain a
/// `Duration:` line.
Duration? _probeDurationInIsolate(String ffmpeg, String input) {
  // Run synchronously inside the worker isolate; ffmpeg `-i` only
  // inspects metadata so this typically returns in < 2s.
  final result = Process.runSync(ffmpeg, ['-hide_banner', '-i', input]);
  if (result.exitCode != 0 && result.exitCode != 1) {
    return null;
  }
  final stderr = result.stderr is String
      ? result.stderr as String
      : String.fromCharCodes((result.stderr as List<int>?) ?? const <int>[]);
  final sec = FfmpegMediaProbe.parseDurationSeconds(stderr);
  if (sec == null || sec <= 0) return null;
  return Duration(seconds: sec);
}
