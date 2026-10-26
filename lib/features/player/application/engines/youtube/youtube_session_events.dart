part of 'youtube_session.dart';

/// The session's event bus: broadcast streams, emit verbs, and teardown.
mixin YoutubeSessionEvents
    on YoutubeSessionBase, YoutubeSessionWebViewLifecycle, YoutubeSessionHint {
  final StreamController<Duration> positionCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> durationCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<bool> playingCtrl = StreamController<bool>.broadcast();
  final StreamController<bool> bufferingCtrl =
      StreamController<bool>.broadcast();
  final StreamController<void> completedCtrl =
      StreamController<void>.broadcast();

  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;
  bool _firstBufferingOffReceived = false;

  Stream<Duration> get position => positionCtrl.stream;
  Stream<Duration> get duration => durationCtrl.stream;
  Stream<bool> get playingStream => playingCtrl.stream;
  Stream<bool> get bufferingStream => bufferingCtrl.stream;
  Stream<void> get completed => completedCtrl.stream;

  Duration get lastPosition => _lastPosition;
  Duration get lastDuration => _lastDuration;

  ({bool playing, bool buffering}) get transportSnapshot =>
      (playing: _playing, buffering: _buffering);

  void emitPosition(Duration d) {
    if (_disposed || positionCtrl.isClosed) return;
    if (d == _lastPosition) return;
    _lastPosition = d;
    positionCtrl.add(d);
  }

  void emitDuration(Duration d) {
    if (_disposed || durationCtrl.isClosed) return;
    if (d == _lastDuration) return;
    _lastDuration = d;
    durationCtrl.add(d);
  }

  void emitPlaying(bool v) {
    if (_disposed || playingCtrl.isClosed) return;
    if (v == _playing) return;
    _playing = v;
    playingCtrl.add(v);
    playRetry.notePlayingTransition(v);
    if (v) {
      _cancelHint();
      if (_tapToPlayHintActive) {
        _tapToPlayHintActive = false;
        bumpMountTick();
      }
    }
  }

  void emitBuffering(bool v) {
    if (_disposed || bufferingCtrl.isClosed) return;
    if (v == _buffering) return;
    _buffering = v;
    bufferingCtrl.add(v);
    if (!v && !_firstBufferingOffReceived) {
      _firstBufferingOffReceived = true;
      bumpMountTick();
    }
    if (v) {
      _cancelHint();
      if (_tapToPlayHintActive) {
        _tapToPlayHintActive = false;
        bumpMountTick();
      }
    } else {
      _scheduleHint();
    }
  }

  Future<void> closeStreams() async {
    _cancelHint();
    _disposed = true;
    _mountRequested = false;
    bumpMountTick();
    await positionCtrl.close();
    await durationCtrl.close();
    await playingCtrl.close();
    await bufferingCtrl.close();
    await completedCtrl.close();
  }
}
