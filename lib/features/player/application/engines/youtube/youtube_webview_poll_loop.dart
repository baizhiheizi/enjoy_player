/// Position/duration polling loop for the YouTube watch WebView.
library;

import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_audible_playback_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_js_channel.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_monotonic_clock.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_play_retry_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_video_event.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';

typedef YoutubePlaybackProgressFn = void Function(Duration position);

/// Injectable poll body for unit tests (defaults to
/// [YoutubeWebViewBridge.poll]).
typedef YoutubePollFn =
    Future<void> Function({
      required bool disposed,
      required YoutubeJsChannel? channel,
      required void Function({
        required Duration position,
        Duration? newDuration,
        required bool jsPaused,
        required bool jsEnded,
      })
      onResult,
    });

/// Injectable immediate-pause retry play (defaults to
/// [YoutubeWebViewBridge.play]).
typedef YoutubeRetryPlayFn = Future<void> Function(YoutubeJsChannel? channel);

final _logPoll = logNamed('YouTubeWebViewPollLoop');

/// DOM poll for `<video>` play state (see [YoutubeWebViewBridge.poll]).
///
/// A one-shot [Timer] chain, not [Timer.periodic]: the cadence is a decision
/// made per tick. While anything is live — playing, an unconfirmed pause
/// streak, a paused position that is still moving — it is [pollTick]; once a
/// pause is CONFIRMED and quiet it backs off to [pausedPollBackoff] (issue
/// #662), escalates to [quietPollBackoff] after [quietEscalationAfter] of
/// uninterrupted quiet (issue #810 G), and [start] puts it back on every play
/// intent or state transition.
class YoutubeWebViewPollLoop {
  YoutubeWebViewPollLoop({
    required this.session,
    required this.jsChannel,
    required this.onFirstPlaying,
    this.onPlaybackProgress,
    this.pollTick = YoutubeAudiblePlaybackPolicy.pollTick,
    this.pausedPollBackoff = defaultPausedPollBackoff,
    this.quietPollBackoff = defaultQuietPollBackoff,
    this.quietEscalationAfter = defaultQuietEscalationAfter,
    MonotonicClock? clock,
    YoutubePollFn? pollFn,
    YoutubeRetryPlayFn? retryPlay,
  }) : clock = clock ?? StopwatchClock(),
       pollFn = pollFn ?? YoutubeWebViewBridge.poll,
       retryPlay =
           retryPlay ??
           ((channel) async {
             await YoutubeWebViewBridge.refocusWindow(channel);
             await YoutubeWebViewBridge.playWhenReady(channel);
           });

  /// Cadence once a pause is confirmed AND the position has stopped moving
  /// (issue #662). Shadow reading pauses a lot, and every tick is a JS
  /// evaluation inside the WebView; 250 ms buys nothing on a paused element.
  /// Never applied before a pause is confirmed — the confirmation window
  /// itself ([YoutubeSession.pauseConfirmPollTicks] × [pollTick], which the
  /// audible-playback joint invariant is checked against) must keep its full
  /// resolution, and an idle-but-never-played document still needs fast
  /// sampling to catch its first metadata.
  static const Duration defaultPausedPollBackoff = Duration(seconds: 1);

  /// Cadence once a confirmed pause has stayed quiet for
  /// [quietEscalationAfter] (issue #810 G): a tab left paused for the rest of
  /// the session must not keep a JS eval + timer wakeup per second alive.
  /// Any play intent, state transition, or position movement re-arms the
  /// fast cadences through [start] / the quiet-reset.
  static const Duration defaultQuietPollBackoff = Duration(seconds: 30);

  /// Uninterrupted quiet a confirmed pause must accumulate before the loop
  /// escalates from [pausedPollBackoff] to [quietPollBackoff].
  static const Duration defaultQuietEscalationAfter = Duration(minutes: 2);

  final YoutubeSession session;
  final YoutubeJsChannel? Function() jsChannel;
  final YoutubeFirstPlayingFn onFirstPlaying;

  /// Notifies when position advances (volume-restore progress gate).
  final YoutubePlaybackProgressFn? onPlaybackProgress;

  final YoutubePollFn pollFn;

  /// One-shot play re-issue for the immediate-pause retry (D8).
  final YoutubeRetryPlayFn retryPlay;

  /// Live cadence — [YoutubeAudiblePlaybackPolicy.pollTick] is the canonical
  /// home of the default (the pause-confirmation invariant reads against it).
  final Duration pollTick;

  /// Cadence while a confirmed pause sits quiet; see
  /// [defaultPausedPollBackoff].
  final Duration pausedPollBackoff;

  /// Deep cadence once the quiet has outlived [quietEscalationAfter]; see
  /// [defaultQuietPollBackoff].
  final Duration quietPollBackoff;

  /// Quiet window that promotes [pausedPollBackoff] to [quietPollBackoff].
  final Duration quietEscalationAfter;

  /// Measures the quiet window on a monotonic source (issue #665).
  final MonotonicClock clock;

  Timer? _pollTimer;
  Timer? _pollKickTimer;

  /// A poll is awaited but not finished yet. The timer chain does not wait
  /// for the previous callback, so a read that outlives one [pollTick] — a
  /// heavy page, the inject sweep, a GC pause — used to let the next tick
  /// issue a second read while the first was still outstanding. Two
  /// overlapping reads resolve in completion order, not issue order, so the
  /// OLDER DOM snapshot could apply last: a stale `s=1` landing after
  /// end-of-media runs [YoutubeSession.notePlayingConfirmed], which clears
  /// `_playbackCompleted` and re-emits `playing=true` on a video that is
  /// already over (issue #655). Dropping the tick rather than queuing it
  /// keeps the cadence self-correcting — the next period samples the DOM
  /// again, so a slow page loses nothing but the ordering hazard.
  bool _pollInFlight = false;

  /// A pause has been confirmed since the last play intent. The backoff is
  /// keyed to a CONFIRMED pause only: [decidePollTransition] reports
  /// [PauseStreaking] while Dart still believes it is playing, and every
  /// later paused read is a [PollIdleTick], so "idle" alone would back the
  /// loop off before it ever confirmed anything.
  bool _pauseConfirmed = false;

  /// The confirmed pause is not producing new information — the position has
  /// stopped moving since the previous read.
  bool _pauseQuiet = false;

  /// When the current quiet stretch began (`null` while not quiet) — the
  /// [quietEscalationAfter] window is measured from here on [clock].
  Duration? _quietSince;

  /// Position from the previous read; the "quiet" half of the backoff test.
  Duration _lastReadPosition = Duration.zero;

  bool get isRunning => _pollTimer != null;

  void scheduleKick() {
    _pollKickTimer?.cancel();
    _pollKickTimer = Timer(const Duration(milliseconds: 500), () {
      _pollKickTimer = null;
      if (!session.disposed) start();
    });
  }

  void start() {
    _pauseConfirmed = false;
    _pauseQuiet = false;
    _quietSince = null;
    session.resetPauseStreak();
    _pollTimer?.cancel();
    _scheduleNext();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollKickTimer?.cancel();
    _pollKickTimer = null;
  }

  Duration _nextDelay() {
    if (!_pauseConfirmed || !_pauseQuiet) return pollTick;
    final quietSince = _quietSince;
    if (quietSince == null) return pausedPollBackoff;
    final quietFor = clock.now() - quietSince;
    return quietFor >= quietEscalationAfter
        ? quietPollBackoff
        : pausedPollBackoff;
  }

  void _notePauseQuiet({required bool positionMoved}) {
    _pauseQuiet = !positionMoved;
    if (_pauseQuiet) {
      _quietSince ??= clock.now();
    } else {
      _quietSince = null;
    }
  }

  void _scheduleNext() {
    _pollTimer = Timer(_nextDelay(), _onTick);
  }

  /// One-shot chain link. Re-arms BEFORE the read so the cadence stays
  /// independent of read latency — exactly the [Timer.periodic] property the
  /// in-flight guard was written against.
  void _onTick() {
    _scheduleNext();
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    try {
      await pollFn(
        disposed: session.disposed,
        channel: jsChannel(),
        onResult:
            ({
              required Duration position,
              Duration? newDuration,
              required bool jsPaused,
              required bool jsEnded,
            }) {
              if (session.disposed) return;
              session.emitPosition(position);
              final positionMoved = position != _lastReadPosition;
              _lastReadPosition = position;
              if (newDuration != null &&
                  newDuration > Duration.zero &&
                  newDuration != session.lastDuration) {
                session.emitDuration(newDuration);
              }
              if (!jsPaused && !jsEnded) {
                onPlaybackProgress?.call(position);
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
                  session.noteEnded();
                  stop();
                case PauseStreaking(:final confirmed, :final newStreak):
                  session.notePauseStreak(newStreak);
                  if (confirmed) {
                    _pauseConfirmed = true;
                    _notePauseQuiet(positionMoved: positionMoved);
                    final immediate = session.isImmediatePause();
                    final retry = session.playRetry.decideConfirmedPause(
                      immediate: immediate,
                      disposed: session.disposed,
                      playbackCompleted: session.playbackCompleted,
                    );
                    _logPoll.fine(
                      'youtube pause confirmed vid=${session.videoId} '
                      'positionMs=${position.inMilliseconds} '
                      'immediate=$immediate '
                      'explicitPlay=${session.explicitPlayAttempted}',
                    );
                    if (immediate) {
                      _logPoll.info(
                        'youtube immediate pause vid=${session.videoId} '
                        'positionMs=${position.inMilliseconds}',
                      );
                    }
                    session.notePauseConfirmed();
                    switch (retry) {
                      case RetryPlayOnce():
                        session.clearUserPlayInFlight();
                        session.noteAutoPlayRetry();
                        _logPoll.info(
                          'youtube immediate pause retry vid='
                          '${session.videoId}',
                        );
                        unawaited(
                          retryPlay(jsChannel()).catchError((
                            Object error,
                            StackTrace stackTrace,
                          ) {
                            _logPoll.warning(
                              'youtube immediate pause retry failed '
                              'vid=${session.videoId}',
                              error,
                              stackTrace,
                            );
                          }),
                        );
                      case SurfacePause():
                        if (immediate || session.explicitPlayAttempted) {
                          session.scheduleRecoveryHint();
                        }
                    }
                  }
                case PollPlaying():
                  session.notePlayingConfirmed();
                  onFirstPlaying();
                  if (session.buffering) {
                    session.emitBuffering(false);
                  }
                  _pauseConfirmed = false;
                  _pauseQuiet = false;
                  _quietSince = null;
                case PollIdleTick():
                  session.resetPauseStreak();
                  if (_pauseConfirmed) {
                    _notePauseQuiet(positionMoved: positionMoved);
                  }
              }
            },
      );
    } finally {
      _pollInFlight = false;
    }
  }
}
