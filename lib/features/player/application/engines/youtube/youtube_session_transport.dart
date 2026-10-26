part of 'youtube_session.dart';

/// Transport command orchestration and the end-of-media latch.
mixin YoutubeSessionTransport
    on
        YoutubeSessionBase,
        YoutubeSessionEvents,
        YoutubeSessionWatchNavigation,
        YoutubeSessionVolumeRestore,
        YoutubeSessionHint,
        YoutubeSessionWebViewLifecycle {
  /// The D8 budget is live only while its attempt is unresolved in time —
  /// see [YouTubePlayRetryPolicy.userPlayInFlight], which owns the
  /// fulfilment condition.
  bool get userPlayInFlight => playRetry.userPlayInFlight;

  int get pausedPollStreak => _pausedPollStreak;

  /// Transitions [_playbackCompleted] to true and emits a [completed] event.
  /// Idempotent — only the first call emits; subsequent calls are a no-op.
  /// [resetCompletionFlag] re-arms the emission for the next end-of-media.
  void markCompleted() {
    if (_playbackCompleted) return;
    _playbackCompleted = true;
    if (!_disposed && !completedCtrl.isClosed) {
      completedCtrl.add(null);
    }
  }

  /// Clears the end-of-media latch so the next [play] drives the `<video>`
  /// directly instead of reloading the watch page (ADR-0044).
  void resetCompletionFlag() => _playbackCompleted = false;

  /// Latches and one-shot bookkeeping that open and clear must both clear, so
  /// the two paths cannot drift apart (issue #668).
  ///
  /// Deliberately open-only stays out: [_loggedFirstPlaying],
  /// [_firstBufferingOffReceived] and the document bump are open-specific, and
  /// [_mountRequested] is clear-specific. Emits are left to the callers — open
  /// and clear transition buffering in opposite directions.
  void _resetTransportLatches({required String videoId}) {
    _cancelHint();
    _tapToPlayHintActive = false;
    _explicitPlayAttempted = false;
    playRetry.reset();
    clearVolumeRestorePending();
    _volumeRestoredDocGen = -1;
    _videoId = videoId;
    _playbackCompleted = false;
    resetWatchPageExpectations(firstPlaying: false);
  }

  void resetForOpen(String newVideoId) {
    _resetTransportLatches(videoId: newVideoId);
    _loggedFirstPlaying = false;
    _firstBufferingOffReceived = false;
    noteWatchDocumentLoaded();
    emitBuffering(true);
    emitPlaying(false);
    emitPosition(Duration.zero);
    emitDuration(Duration.zero);
  }

  void resetForClear({bool keepMounted = false}) {
    _resetTransportLatches(videoId: '');
    _mountRequested = keepMounted;
    emitPlaying(false);
    emitBuffering(false);
    emitPosition(Duration.zero);
    bumpMountTick();
  }

  /// An explicit play command is on the wire (engine [play]/[playOrPause]).
  /// Arms the D8 budget ([YouTubePlayRetryPolicy.beginUserPlay]); stale
  /// buffering clears so the transport button stays retryable.
  void beginUserPlay() {
    playRetry.beginUserPlay();
    if (_buffering && !_playing) {
      emitBuffering(false);
    }
  }

  /// An explicit pause-intent command is on the wire (engine
  /// [pause]/[stop]/the pause branch of [playOrPause]) — consumes the D8
  /// budget and drops the escalation chain, so a deliberate pause is never
  /// auto-resumed.
  void noteUserPauseCommand() => playRetry.noteUserPauseCommand();

  /// Play-after-end-of-media orchestration (engine [play] restart branch,
  /// ADR-0044). Collapses the four transport transitions the engine
  /// previously drove by hand: emit playing=false (so a stale true cannot
  /// arm a budget against a fresh start), arm the D8 budget, emit
  /// buffering=true to put the skeleton back. [emitPlaying] is fired first
  /// so [beginUserPlay]'s "stale-buffering clear" branch (which depends on
  /// !_playing) sees a stable not-playing state.
  ///
  /// The WebView reload + load stay in the engine / webView controller —
  /// they need the bridge and the controller getter.
  void beginPlayAfterEnd() {
    emitPlaying(false);
    beginUserPlay();
    emitBuffering(true);
  }

  /// Stop-orchestration (engine [stop]). Consumes the pause-intent so the
  /// D8 budget cannot un-pause a deliberate stop, surfaces not-playing /
  /// not-buffering, zeroes the position, and re-arms the completion latch
  /// for the next open.
  void stopPlayback() {
    noteUserPauseCommand();
    emitPlaying(false);
    emitBuffering(false);
    emitPosition(Duration.zero);
    resetCompletionFlag();
  }

  /// Settles a transport-command failure (engine [playOrPause] / [play]):
  /// any armed budget is consumed and buffering surfaces false. The
  /// command failed, so the in-flight play is unresolved.
  void noteCommandFailed() {
    playRetry.noteUserPlayUnresolved();
    emitBuffering(false);
  }

  /// Records that the poll loop just spent the D8 budget on a retry.
  void noteAutoPlayRetry() => playRetry.noteAutoPlayRetry();

  /// `playing` observed (DOM event or poll). The in-flight play latch stays
  /// armed: the attempt resolves only when playback outlives the
  /// immediate-pause window (or a failure/pause-intent transition consumes
  /// it). Clearing it here made the D8 retry unreachable for the very
  /// sequence it exists for — the page's post-`playing` correction always
  /// confirmed after the latch was gone.
  void notePlayingConfirmed() {
    _pausedPollStreak = 0;
    _playbackCompleted = false;
    emitPlaying(true);
  }

  /// A programmatic play promise rejected (autoplay policy) or the element
  /// errored: the unresolved user play settles as not-playing.
  void noteUserPlayUnresolved() {
    playRetry.noteUserPlayUnresolved();
    emitPlaying(false);
    emitBuffering(false);
  }

  /// End of media observed (DOM `ended` or poll `s` = 2).
  void noteEnded() {
    _pausedPollStreak = 0;
    playRetry.noteEnded();
    markCompleted();
    emitPlaying(false);
    emitBuffering(false);
  }

  /// The poll loop confirmed a pause (streak ≥
  /// [YoutubeSession.pauseConfirmPollTicks]).
  void notePauseConfirmed() {
    _pausedPollStreak = 0;
    emitPlaying(false);
    emitBuffering(false);
  }

  /// Consumes the one-shot immediate-pause retry budget (D8) before the poll
  /// loop re-issues play; a second immediate pause surfaces to the user.
  void clearUserPlayInFlight() => playRetry.consumeBudget();

  /// Marks an intentional play command (transport / autoplay / recovery).
  void markExplicitPlayAttempt() => _explicitPlayAttempted = true;

  /// Poll bookkeeping: accumulate toward pause confirmation.
  void notePauseStreak(int streak) => _pausedPollStreak = streak;

  /// Poll bookkeeping: forget any half-confirmed pause.
  void resetPauseStreak() => _pausedPollStreak = 0;
}
