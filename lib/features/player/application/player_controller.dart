/// Owns the single `media_kit` [Player] instance and [PlaybackSession] state.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';
import '../../../data/subtitle/embedded_subtitle_service.dart';
import '../domain/echo_window.dart';
import '../domain/playback_session.dart';
import '../domain/player_settings.dart';
import '../../transcript/data/transcript_repository.dart';
import 'echo_mode_provider.dart';
import 'embedded_tracks_notifier.dart';

part 'player_controller.g.dart';

const _prefsKey = 'player_preferences_v1';

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  late final mk.Player _player = mk.Player();
  late final VideoController videoController = VideoController(
    _player,
    // Without an initial size, media_kit_video creates a temporary 1px texture,
    // then frees/recreates it once video params arrive. That texture churn
    // repeatedly trips Flutter's Windows AXTree bridge.
    configuration:
        Platform.isWindows
            ? const VideoControllerConfiguration(width: 1920, height: 1080)
            : const VideoControllerConfiguration(),
  );

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<mk.Tracks>? _tracksSub;

  Timer? _persistDebounce;

  mk.Player get player => _player;

  @override
  PlaybackSession? build() {
    // Force eager construction of [videoController] so mpv has a video output
    // bound BEFORE the first [_player.open()] call. Otherwise the first opened
    // media plays audio only with a blank video surface, because the texture
    // is created lazily during a later rebuild — after playback already began.
    videoController;

    ref.onDispose(() async {
      _persistDebounce?.cancel();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      await _tracksSub?.cancel();
      await _player.dispose();
    });
    return null;
  }

  Future<PlayerPreferences> _readPrefsFromDb() async {
    final db = ref.read(appDatabaseProvider);
    final raw = await db.settingsDao.getValue(_prefsKey);
    if (raw == null) return PlayerPreferences.defaults;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final repeatIdx = (map['repeat'] as int?) ?? 0;
      return PlayerPreferences(
        volume: ((map['volume'] as num?)?.toDouble() ?? 1).clamp(0, 1),
        playbackRate: ((map['rate'] as num?)?.toDouble() ?? 1).clamp(0.25, 2),
        repeatMode:
            RepeatMode.values[repeatIdx.clamp(0, RepeatMode.values.length - 1)],
      );
    } catch (_) {
      return PlayerPreferences.defaults;
    }
  }

  Future<void> applyPreferences(PlayerPreferences prefs) async {
    await _player.setVolume(prefs.volume * 100);
    await _player.setRate(prefs.playbackRate);
  }

  Future<void> openMedia(String mediaId) async {
    final db = ref.read(appDatabaseProvider);
    final row = await db.mediaDao.getById(mediaId);
    if (row == null) return;

    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _tracksSub?.cancel();

    await _player.open(mk.Media(row.sourceUri));

    _subscribeEmbeddedTracks(mediaId, row);

    final prefs = await _readPrefsFromDb();
    await applyPreferences(prefs);

    final persisted = await db.sessionDao.getForMedia(mediaId);
    final posMs = persisted?.positionMs ?? 0;
    if (posMs > 0) {
      await _player.seek(Duration(milliseconds: posMs));
    }

    if (persisted != null && persisted.echoActive) {
      ref
          .read(echoModeProvider.notifier)
          .restoreFromSession(
            startLine: persisted.echoStartLine,
            endLine: persisted.echoEndLine,
            echoStartMs: persisted.echoStartMs,
            echoEndMs: persisted.echoEndMs,
          );
    } else {
      ref.read(echoModeProvider.notifier).deactivate();
    }

    final now = DateTime.now();
    state = PlaybackSession(
      mediaId: row.id,
      mediaType: row.kind,
      mediaTitle: row.title,
      thumbnailUrl: row.thumbnailPath,
      durationSeconds:
          row.durationMs > 0 ? row.durationMs / 1000.0 : posMs / 1000.0,
      currentTimeSeconds: posMs / 1000.0,
      currentSegmentIndex: persisted?.currentSegmentIndex ?? -1,
      language: row.language,
      startedAt: now,
      lastActiveAt: now,
    );

    _subscribeStreams(mediaId, row);
  }

  void _subscribeStreams(String mediaId, MediaRow row) {
    _positionSub = _player.stream.position.listen((pos) {
      final seconds = pos.inMilliseconds / 1000.0;
      unawaited(_applyEcho(seconds));
      state = state?.copyWith(
        currentTimeSeconds: seconds,
        lastActiveAt: DateTime.now(),
      );
      _schedulePersist(mediaId);
    });

    _durationSub = _player.stream.duration.listen((d) async {
      if (d <= Duration.zero) return;
      final ms = d.inMilliseconds;
      state = state?.copyWith(durationSeconds: ms / 1000.0);
      final db = ref.read(appDatabaseProvider);
      if (row.durationMs == 0) {
        await db.mediaDao.insertRow(
          row.copyWith(durationMs: ms, updatedAt: DateTime.now()),
        );
      }
    });
  }

  Future<void> _applyEcho(double positionSeconds) async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final dur = state?.durationSeconds;
    final window = normalizeEchoWindow((
      active: true,
      startTimeSeconds: echo.startTimeSeconds,
      endTimeSeconds: echo.endTimeSeconds,
      durationSeconds: dur != null && dur > 0 ? dur : null,
    ));
    if (window == null) return;
    final decision = decideEchoPlaybackTime(positionSeconds, window);
    switch (decision) {
      case EchoOk():
        return;
      case EchoClamp(:final timeSeconds):
      case EchoLoop(:final timeSeconds):
        await _player.seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
    }
  }

  void _schedulePersist(String mediaId) {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 450), () async {
      final s = state;
      if (s == null) return;
      final db = ref.read(appDatabaseProvider);
      final echo = ref.read(echoModeProvider);
      // Preserve existing transcript selections — only write position/echo fields.
      final existing = await db.sessionDao.getForMedia(mediaId);
      await db.sessionDao.upsert(
        PlaybackSessionRow(
          mediaId: mediaId,
          positionMs: (s.currentTimeSeconds * 1000).round(),
          currentSegmentIndex: s.currentSegmentIndex,
          echoActive: echo.active,
          echoStartLine: echo.startLineIndex,
          echoEndLine: echo.endLineIndex,
          echoStartMs: (echo.startTimeSeconds * 1000).round(),
          echoEndMs: (echo.endTimeSeconds * 1000).round(),
          primaryTranscriptId: existing?.primaryTranscriptId,
          secondaryTranscriptId: existing?.secondaryTranscriptId,
          lastActiveAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> seekTo(Duration target) async {
    final echo = ref.read(echoModeProvider);
    var seconds = target.inMilliseconds / 1000.0;
    if (echo.active) {
      final dur = state?.durationSeconds;
      final window = normalizeEchoWindow((
        active: true,
        startTimeSeconds: echo.startTimeSeconds,
        endTimeSeconds: echo.endTimeSeconds,
        durationSeconds: dur != null && dur > 0 ? dur : null,
      ));
      if (window != null) {
        seconds = clampSeekTimeToEchoWindow(seconds, window);
      }
    }
    await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> seekToSeconds(double seconds) async {
    await seekTo(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> togglePlay() async {
    await _player.playOrPause();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> clear() async {
    _persistDebounce?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _tracksSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    _tracksSub = null;
    await _player.stop();
    ref.read(echoModeProvider.notifier).deactivate();
    state = null;
  }

  /// Listens once for media_kit's track list, then extracts + upserts any
  /// embedded subtitle streams not already stored in the DB.
  void _subscribeEmbeddedTracks(String mediaId, MediaRow row) {
    _tracksSub?.cancel();
    _tracksSub = _player.stream.tracks
        .where((t) => t.subtitle.isNotEmpty)
        .take(1)
        .listen((tracks) async {
          final db = ref.read(appDatabaseProvider);
          final existing = await db.transcriptDao.listForMedia(mediaId);
          final existingIndices =
              existing
                  .where((r) => r.isEmbedded && r.trackIndex != null)
                  .map((r) => r.trackIndex!)
                  .toSet();

          final extracted = await const EmbeddedSubtitleService().extractTracks(
            mediaId: mediaId,
            mediaSourceUri: row.sourceUri,
            tracks: tracks.subtitle,
            existingTrackIndices: existingIndices,
          );

          if (extracted.isEmpty) return;

          final repo = TranscriptRepository(db);
          await repo.upsertEmbeddedTracks(extracted);

          // Auto-select first embedded track as primary if none is set yet.
          final session = await db.sessionDao.getForMedia(mediaId);
          if (session?.primaryTranscriptId == null) {
            await db.sessionDao.updatePrimaryTranscript(
              mediaId,
              extracted.first.id,
            );
          }

          // Signal to the UI that new tracks were found (for the snackbar).
          ref
              .read(embeddedTracksProvider.notifier)
              .notifyFound(mediaId, extracted.length);
        });
  }
}
