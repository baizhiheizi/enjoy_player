import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CraftPreviewController extends ChangeNotifier {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  bool _disposed = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> toggle(Uint8List bytes) async {
    if (_disposed) return;
    final player = _player ??= _createPlayer();

    if (_isPlaying) {
      await player.pause();
      if (_disposed) return;
      _isPlaying = false;
      notifyListeners();
      return;
    }

    if (_position == _duration && _duration > Duration.zero) {
      await player.seek(Duration.zero);
    }
    await player.play(BytesSource(bytes));
    if (_disposed) return;
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> seek(Duration value) async {
    if (_disposed) return;
    await _player?.seek(value);
    if (_disposed) return;
    _position = value;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    final player = _player;
    _player = null;
    _cancelSubscriptions();
    if (player != null) unawaited(player.dispose());
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    final player = _player;
    _player = null;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _positionSub = player.onPositionChanged.listen((value) {
      if (_disposed) return;
      _position = _duration > Duration.zero && value > _duration
          ? _duration
          : value;
      notifyListeners();
    });
    _durationSub = player.onDurationChanged.listen((value) {
      if (_disposed) return;
      _duration = value;
      if (_position > value) _position = value;
      notifyListeners();
    });
    _completeSub = player.onPlayerComplete.listen((_) {
      if (_disposed) return;
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
    return player;
  }

  void _cancelSubscriptions() {
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_completeSub?.cancel());
    _positionSub = null;
    _durationSub = null;
    _completeSub = null;
  }
}
