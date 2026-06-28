/// Position/duration polling loop for the YouTube watch WebView.
library;

import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_state_poller.dart';

typedef YoutubeFirstPlayingFn = void Function();

/// Periodic DOM poll for `<video>` play state (see [YoutubeStatePoller]).
class YoutubeWebViewPollLoop {
  YoutubeWebViewPollLoop({
    required this.session,
    required this.webController,
    required this.onFirstPlaying,
  });

  final YoutubeSession session;
  final InAppWebViewController? Function() webController;
  final YoutubeFirstPlayingFn onFirstPlaying;

  Timer? _pollTimer;
  Timer? _pollKickTimer;

  void scheduleKick() {
    _pollKickTimer?.cancel();
    _pollKickTimer = Timer(const Duration(milliseconds: 500), () {
      _pollKickTimer = null;
      if (!session.disposed) start();
    });
  }

  void start() {
    if (_pollTimer != null) return;
    session.pausedPollStreak = 0;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tick(),
    );
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollKickTimer?.cancel();
    _pollKickTimer = null;
  }

  Future<void> _tick() async {
    await YoutubeStatePoller.poll(
      disposed: session.disposed,
      web: webController(),
      onResult:
          ({
            required Duration position,
            Duration? newDuration,
            required bool jsPaused,
            required bool jsEnded,
          }) {
            if (session.disposed) return;
            session.emitPosition(position);
            if (newDuration != null &&
                newDuration > Duration.zero &&
                newDuration != session.lastDuration) {
              session.emitDuration(newDuration);
            }
            if (jsEnded && !session.playbackCompleted) {
              session.pausedPollStreak = 0;
              session.playbackCompleted = true;
              stop();
              session.emitPlaying(false);
            } else if (jsPaused && session.playing && !jsEnded) {
              session.pausedPollStreak++;
              if (session.pausedPollStreak >= YoutubeSession.pauseConfirmPollTicks) {
                session.pausedPollStreak = 0;
                session.emitPlaying(false);
                stop();
              }
            } else {
              session.pausedPollStreak = 0;
              if (!jsPaused && !jsEnded) {
                session.playbackCompleted = false;
                session.emitPlaying(true);
                onFirstPlaying();
                if (session.buffering) {
                  session.emitBuffering(false);
                }
              }
            }
          },
    );
  }
}
