/// Abstraction over the playback backend (default: media_kit) for testability.
library;

import 'package:media_kit/media_kit.dart' as mk;

/// Contract implemented by [MediaKitPlayerEngine] in production and fakes in tests.
abstract class PlayerEngine {
  /// Underlying native player (needed for [VideoController] binding).
  mk.Player get player;

  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<bool> get playing;
  Stream<bool> get buffering;
  Stream<mk.Tracks> get tracks;

  Future<void> openUri(String uri);

  Future<void> seek(Duration target);

  Future<void> setRate(double rate);

  /// [volume] is 0.0–1.0 (mapped to player units in implementation).
  Future<void> setVolumeNormalized(double volume);

  Future<void> playOrPause();

  Future<void> play();

  Future<void> stop();

  Future<void> dispose();
}

/// Single [mk.Player] instance — ADR-0003.
class MediaKitPlayerEngine implements PlayerEngine {
  MediaKitPlayerEngine() : _player = mk.Player();

  final mk.Player _player;

  @override
  mk.Player get player => _player;

  @override
  Stream<Duration> get position => _player.stream.position;

  @override
  Stream<Duration> get duration => _player.stream.duration;

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get buffering => _player.stream.buffering;

  @override
  Stream<mk.Tracks> get tracks => _player.stream.tracks;

  @override
  Future<void> openUri(String uri) => _player.open(mk.Media(uri));

  @override
  Future<void> seek(Duration target) => _player.seek(target);

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setVolumeNormalized(double volume) =>
      _player.setVolume(volume.clamp(0, 1) * 100);

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
