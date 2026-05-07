import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/features/player/application/player_engine.dart';

/// Test double with controllable streams (tracks never emits — avoids embedded extract).
class FakePlayerEngine implements PlayerEngine {
  FakePlayerEngine();

  mk.Player? _playerInstance;

  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _duration =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playing =
      StreamController<bool>.broadcast();
  final StreamController<bool> _buffering =
      StreamController<bool>.broadcast();

  final List<String> openUris = <String>[];
  final List<Duration> seekCalls = <Duration>[];

  /// Optional hook to stall [openUri] (re-entrancy tests).
  Future<void> Function()? openDelay;

  double lastVolume = -1;
  double lastRate = -1;

  void emitPosition(Duration d) {
    if (!_position.isClosed) _position.add(d);
  }

  void emitDuration(Duration d) {
    if (!_duration.isClosed) _duration.add(d);
  }

  @override
  mk.Player get player => _playerInstance ??= mk.Player();

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<bool> get buffering => _buffering.stream;

  @override
  Stream<mk.Tracks> get tracks async* {
    // Intentionally never emits so [EmbeddedTrackSync] stays idle in unit tests.
  }

  @override
  Future<void> openUri(String uri) async {
    openUris.add(uri);
    final delay = openDelay;
    if (delay != null) await delay();
  }

  @override
  Future<void> seek(Duration target) async {
    seekCalls.add(target);
  }

  @override
  Future<void> setRate(double rate) async {
    lastRate = rate;
  }

  @override
  Future<void> setVolumeNormalized(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _position.close();
    await _duration.close();
    await _playing.close();
    await _buffering.close();
    await _playerInstance?.dispose();
    _playerInstance = null;
  }
}
