/// Position/duration stream subscriptions, echo clamping, and session persistence.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/position_buckets.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'playback_session_persister.dart';

final _positionLog = logNamed('PlayerPositionTracker');

/// Manages engine position/duration listeners for one open generation.
class PlayerPositionTracker {
  PlayerPositionTracker({
    required this.ref,
    required this.getEngine,
    required this.getSession,
    required this.setSession,
    required this.currentOpenGeneration,
  });

  final Ref ref;
  final PlayerEngine Function() getEngine;
  final PlaybackSession? Function() getSession;
  final void Function(PlaybackSession? next) setSession;
  final int Function() currentOpenGeneration;

  int? _subscribedGeneration;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  int? _lastPositionEmitBucket;
  int? _lastEchoApplyBucket;

  Future<void> cancel() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    _lastPositionEmitBucket = null;
    _lastEchoApplyBucket = null;
  }

  void subscribe({
    required int openGeneration,
    required String mediaId,
    required String dexieTargetType,
    required MediaKind kind,
    required VideoRow? video,
    required AudioRow? audio,
  }) {
    _subscribedGeneration = openGeneration;
    _lastPositionEmitBucket = null;
    _lastEchoApplyBucket = null;

    const positionBucketMs = kPositionBucketEchoApplyMs;
    _positionSub = getEngine().position.listen(
      (pos) {
        if (_subscribedGeneration != currentOpenGeneration()) return;
        final seconds = pos.inMilliseconds / 1000.0;

        final bucket = pos.inMilliseconds ~/ positionBucketMs;
        final prevSec = getSession()?.currentTimeSeconds;
        final likelySeek = prevSec != null && (seconds - prevSec).abs() > 0.35;
        if (likelySeek || bucket != _lastEchoApplyBucket) {
          _lastEchoApplyBucket = bucket;
          unawaited(_applyEcho(seconds));
        }

        if (!likelySeek && bucket == _lastPositionEmitBucket) {
          return;
        }
        _lastPositionEmitBucket = bucket;

        setSession(
          getSession()?.copyWith(
            currentTimeSeconds: seconds,
            lastActiveAt: DateTime.now(),
          ),
        );
        final s = getSession();
        if (s != null) {
          ref
              .read(playbackSessionPersisterProvider)
              .schedule(
                mediaId: mediaId,
                dexieTargetType: dexieTargetType,
                session: s,
              );
        }
      },
      onError: (Object e, StackTrace st) {
        _positionLog.warning('engine position stream errored', e, st);
      },
    );

    _durationSub = getEngine().duration.listen(
      (d) async {
        if (_subscribedGeneration != currentOpenGeneration()) return;
        if (d <= Duration.zero) return;
        final newSec = d.inMilliseconds / 1000.0;
        final prevSec = getSession()?.durationSeconds;
        if (prevSec != null && (newSec - prevSec).abs() < 0.001) {
          return;
        }
        final sec = d.inMilliseconds ~/ 1000;
        setSession(getSession()?.copyWith(durationSeconds: newSec));
        final db = ref.read(appDatabaseProvider);
        if (kind == MediaKind.video &&
            video != null &&
            video.durationSeconds == 0) {
          await db.videoDao.insertRow(
            video.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
          );
        } else if (kind == MediaKind.audio &&
            audio != null &&
            audio.durationSeconds == 0) {
          await db.audioDao.insertRow(
            audio.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
          );
        }
      },
      onError: (Object e, StackTrace st) {
        _positionLog.warning('engine duration stream errored', e, st);
      },
    );
  }

  Future<void> _applyEcho(double positionSeconds) async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final dur = getSession()?.durationSeconds;
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
        await getEngine().seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
      case EchoPauseAndRewind(:final timeSeconds):
        await getEngine().pause();
        await getEngine().seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
    }
  }
}
