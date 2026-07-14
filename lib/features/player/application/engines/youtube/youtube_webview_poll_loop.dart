/// Position/duration polling loop for the YouTube watch WebView.
library;

import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_state_poller.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';

typedef YoutubeFirstPlayingFn = void Function();
typedef YoutubeMediaEndFn = void Function();

final _logPoll = logNamed('YouTubeWebViewPollLoop');

/// Periodic DOM poll for `<video>` play state (see [YoutubeStatePoller]).
class YoutubeWebViewPollLoop {
  YoutubeWebViewPollLoop({
    required this.session,
    required this.webController,
    required this.onFirstPlaying,
    this.repeatMode,
    this.onMediaEnd,
  });

  final YoutubeSession session;
  final InAppWebViewController? Function() webController;
  final YoutubeFirstPlayingFn onFirstPlaying;

  /// Resolve the current repeat mode so [decideOnMediaEnd] can choose between
  /// stop, loop, and segment-loop when the video finishes.
  final RepeatMode Function()? repeatMode;

  /// Called when [decideOnMediaEnd] requests a loop — the consumer (engine)
  /// reloads the watch page so playback restarts from the beginning.
  final YoutubeMediaEndFn? onMediaEnd;

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
            final transition = decidePollTransition(
              jsEnded: jsEnded,
              jsPaused: jsPaused,
              playing: session.playing,
              pausedPollStreak: session.pausedPollStreak,
              pauseConfirmThreshold: YoutubeSession.pauseConfirmPollTicks,
              playbackCompleted: session.playbackCompleted,
            );
            switch (transition) {
              case MediaJustEnded():
                session.pausedPollStreak = 0;
                session.markCompleted();
                final endDecision = decideOnMediaEnd(
                  repeatMode: repeatMode?.call() ?? RepeatMode.none,
                );
                switch (endDecision) {
                  case StopAtEnd():
                    stop();
                    session.emitPlaying(false);
                  case LoopMedia():
                    session.emitPlaying(false);
                    onMediaEnd?.call();
                  case LoopSegment():
                    session.emitPlaying(false);
                    onMediaEnd?.call();
                }
              case PauseStreaking(:final confirmed, :final newStreak):
                session.pausedPollStreak = newStreak;
                if (confirmed) {
                  _logPoll.fine(
                    'youtube pause confirmed vid=${session.videoId} '
                    'positionMs=${position.inMilliseconds}',
                  );
                  session.pausedPollStreak = 0;
                  session.emitPlaying(false);
                  stop();
                }
              case PollPlaying():
                session.pausedPollStreak = 0;
                session.playbackCompleted = false;
                session.emitPlaying(true);
                onFirstPlaying();
                if (session.buffering) {
                  session.emitBuffering(false);
                }
              case PollIdleTick():
                session.pausedPollStreak = 0;
            }
          },
    );
  }
}
