part of 'youtube_session.dart';

/// Watch-document navigation expectations.
mixin YoutubeSessionWatchNavigation on YoutubeSessionBase {
  final ValueNotifier<bool> _loggedFirstPlayingNotifier = ValueNotifier<bool>(
    false,
  );
  bool _watchPageLoadStopReceived = false;
  bool _awaitingColdInitialNavigation = false;
  bool _nonWatchRecoveryScheduled = false;

  ValueListenable<bool> get loggedFirstPlayingListenable =>
      _loggedFirstPlayingNotifier;
  bool get loggedFirstPlaying => _loggedFirstPlayingNotifier.value;
  bool get _loggedFirstPlaying => _loggedFirstPlayingNotifier.value;
  set _loggedFirstPlaying(bool value) {
    if (_disposed) return;
    _loggedFirstPlayingNotifier.value = value;
  }

  bool get watchPageLoadStopReceived => _watchPageLoadStopReceived;
  bool get awaitingColdInitialNavigation => _awaitingColdInitialNavigation;
  bool get nonWatchRecoveryScheduled => _nonWatchRecoveryScheduled;

  /// Clears the "expect a watch page load stop" latches before (re)loading.
  /// [firstPlaying] also forgets that playback ever started (full reload).
  void resetWatchPageExpectations({required bool firstPlaying}) {
    _watchPageLoadStopReceived = false;
    _awaitingColdInitialNavigation = false;
    _nonWatchRecoveryScheduled = false;
    if (firstPlaying) {
      _loggedFirstPlaying = false;
    }
  }

  /// A watch-page load stop arrived: not cold-navigation, no recovery needed.
  void noteWatchPageLoaded() {
    _awaitingColdInitialNavigation = false;
    _watchPageLoadStopReceived = true;
    _nonWatchRecoveryScheduled = false;
  }

  /// The WebView mounted with an initial watch URL already navigating.
  void noteAwaitingColdInitialNavigation() =>
      _awaitingColdInitialNavigation = true;

  /// The WebView went away; its in-flight initial navigation no longer
  /// applies. (Deliberately narrow: dispose must not disturb the load-stop
  /// or recovery latches.)
  void clearAwaitingColdInitialNavigation() =>
      _awaitingColdInitialNavigation = false;

  /// First `playing` observed after an open — arms nudge/watchdog cancel.
  void markFirstPlayingLogged() => _loggedFirstPlaying = true;

  /// A non-watch load stop was seen; verify the watch page once.
  void scheduleNonWatchRecovery() => _nonWatchRecoveryScheduled = true;
}
