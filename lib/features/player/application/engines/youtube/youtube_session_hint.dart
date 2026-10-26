part of 'youtube_session.dart';

/// Tap-to-play hint / recovery-overlay choreography.
mixin YoutubeSessionHint
    on
        YoutubeSessionBase,
        YoutubeSessionWatchNavigation,
        YoutubeSessionWebViewLifecycle {
  bool _tapToPlayHintActive = false;

  Timer? _tapToPlayHintTimer;

  bool get tapToPlayHintActive => _tapToPlayHintActive;

  void _scheduleHint() {
    if (_disposed) return;
    final allowRecovery = _explicitPlayAttempted && !_playing && !_buffering;
    if (_loggedFirstPlaying && !allowRecovery) return;
    _tapToPlayHintTimer?.cancel();
    _tapToPlayHintTimer = Timer(YoutubeSession.tapToPlayHintDelay, () {
      _tapToPlayHintTimer = null;
      if (_disposed || _playing || _buffering) return;
      if (_loggedFirstPlaying && !_explicitPlayAttempted) return;
      if (!_tapToPlayHintActive) {
        _tapToPlayHintActive = true;
        bumpMountTick();
      }
    });
  }

  /// Arms the recovery overlay after play rejection or immediate pause.
  void scheduleRecoveryHint() {
    if (_disposed || _playing) return;
    _scheduleHint();
  }

  void _cancelHint() {
    _tapToPlayHintTimer?.cancel();
    _tapToPlayHintTimer = null;
  }
}
