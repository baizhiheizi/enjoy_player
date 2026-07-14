/// DOM `<video>` event dispatch for [YoutubeWebViewController].
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';

final _logEvents = logNamed('YouTubeWebViewEvents');

typedef YoutubeSeekFn = Future<void> Function(Duration target);
typedef YoutubePollStartFn = void Function();
typedef YoutubePollStopFn = void Function();
typedef YoutubeFirstPlayingFn = void Function();
typedef YoutubeReapplyVolumeFn = Future<void> Function();

/// Handles `onVideoEvent` JavaScript callbacks from the watch page.
class YoutubeWebViewEvents {
  YoutubeWebViewEvents({
    required this.session,
    required this.webController,
    required this.onFirstPlaying,
    required this.startPolling,
    required this.stopPolling,
    required this.reapplyVolume,
    required this.seekTo,
    Duration? volumeRestoreDelay,
  }) : volumeRestoreDelay =
           volumeRestoreDelay ??
           (defaultTargetPlatform == TargetPlatform.windows
               ? windowsVolumeRestoreDelay
               : Duration.zero);

  static const Duration windowsVolumeRestoreDelay = Duration(milliseconds: 400);

  final Duration volumeRestoreDelay;

  final YoutubeSession session;
  final InAppWebViewController? Function() webController;
  final YoutubeFirstPlayingFn onFirstPlaying;
  final YoutubePollStartFn startPolling;
  final YoutubePollStopFn stopPolling;
  final YoutubeReapplyVolumeFn reapplyVolume;
  final YoutubeSeekFn seekTo;

  Timer? _volumeRestoreTimer;

  dynamic handle(List<dynamic> args) {
    if (args.isEmpty) return null;
    final event = args[0] as String;
    switch (event) {
      case 'play':
        session.pausedPollStreak = 0;
        _logEvents.fine('youtube video play requested vid=${session.videoId}');
        break;
      case 'playing':
        final restoreDelay = session.loggedFirstPlaying
            ? Duration.zero
            : volumeRestoreDelay;
        session.pausedPollStreak = 0;
        session.playbackCompleted = false;
        session.emitPlaying(true);
        onFirstPlaying();
        session.emitBuffering(false);
        startPolling();
        applyPendingSeek();
        _scheduleVolumeRestore(restoreDelay);
        _logEvents.fine('youtube video playing vid=${session.videoId}');
        break;
      case 'pause':
        session.pausedPollStreak = 0;
        cancelPendingVolumeRestore();
        _logEvents.fine('youtube video paused vid=${session.videoId}');
        break;
      case 'playRejected':
        cancelPendingVolumeRestore();
        session.emitPlaying(false);
        final reason = args.length > 1 ? '${args[1]}' : 'unknown';
        _logEvents.warning(
          'youtube play rejected vid=${session.videoId} reason=$reason',
        );
        break;
      case 'ended':
        session.pausedPollStreak = 0;
        cancelPendingVolumeRestore();
        session.markCompleted();
        stopPolling();
        session.emitPlaying(false);
        unawaited(YoutubeWebViewBridge.pauseVideoElement(webController()));
        break;
      case 'waiting':
        session.emitBuffering(true);
        break;
      case 'canplay':
        if (session.buffering) {
          session.emitBuffering(false);
        }
        break;
      case 'loadedmetadata':
        startPolling();
        if (args.length > 1) {
          final dur = (args[1] as num).toDouble();
          if (dur > 0 && dur.isFinite) {
            session.emitDuration(Duration(milliseconds: (dur * 1000).round()));
            applyPendingSeek();
          }
        }
        break;
      case 'error':
        cancelPendingVolumeRestore();
        _logEvents.warning('YouTube video element error');
        session.emitBuffering(false);
        break;
      default:
        break;
    }
    return null;
  }

  void _scheduleVolumeRestore(Duration delay) {
    cancelPendingVolumeRestore();
    if (delay == Duration.zero) {
      unawaited(_restoreVolume(delay));
      return;
    }
    _volumeRestoreTimer = Timer(delay, () {
      _volumeRestoreTimer = null;
      if (session.disposed || !session.playing) return;
      unawaited(_restoreVolume(delay));
    });
  }

  Future<void> _restoreVolume(Duration delay) async {
    try {
      await reapplyVolume();
      _logEvents.fine(
        'youtube volume restored vid=${session.videoId} '
        'delayMs=${delay.inMilliseconds}',
      );
    } on Object catch (error, stackTrace) {
      _logEvents.warning(
        'youtube volume restore failed vid=${session.videoId}',
        error,
        stackTrace,
      );
    }
  }

  void cancelPendingVolumeRestore() {
    _volumeRestoreTimer?.cancel();
    _volumeRestoreTimer = null;
  }

  void applyPendingSeek() {
    final secs = session.pendingSeekSeconds;
    if (secs == null || secs <= 0) return;
    session.pendingSeekSeconds = null;
    unawaited(seekTo(Duration(milliseconds: (secs * 1000).round())));
  }
}
