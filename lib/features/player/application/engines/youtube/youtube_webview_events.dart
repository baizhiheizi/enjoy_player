/// DOM `<video>` event dispatch for [YoutubeWebViewController].
library;

import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';

final _logEvents = logNamed('YoutubeWebViewEvents');

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
  });

  final YoutubeSession session;
  final InAppWebViewController? Function() webController;
  final YoutubeFirstPlayingFn onFirstPlaying;
  final YoutubePollStartFn startPolling;
  final YoutubePollStopFn stopPolling;
  final YoutubeReapplyVolumeFn reapplyVolume;
  final YoutubeSeekFn seekTo;

  dynamic handle(List<dynamic> args) {
    if (args.isEmpty) return null;
    final event = args[0] as String;
    switch (event) {
      case 'play':
      case 'playing':
        session.pausedPollStreak = 0;
        session.playbackCompleted = false;
        session.emitPlaying(true);
        onFirstPlaying();
        session.emitBuffering(false);
        startPolling();
        applyPendingSeek();
        unawaited(reapplyVolume());
        break;
      case 'pause':
        session.pausedPollStreak = 0;
        break;
      case 'ended':
        session.pausedPollStreak = 0;
        session.playbackCompleted = true;
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
        _logEvents.warning('YouTube video element error');
        session.emitBuffering(false);
        break;
      default:
        break;
    }
    return null;
  }

  void applyPendingSeek() {
    final secs = session.pendingSeekSeconds;
    if (secs == null || secs <= 0) return;
    session.pendingSeekSeconds = null;
    unawaited(seekTo(Duration(milliseconds: (secs * 1000).round())));
  }
}
