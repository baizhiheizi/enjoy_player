/// Abstraction over the playback backend (default: media_kit) for testability.
library;

import 'dart:typed_data';

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

  /// Turns off libmpv / player subtitle output; transcripts use in-app UI only.
  Future<void> disableRenderedSubtitles();

  Future<void> seek(Duration target);

  Future<void> setRate(double rate);

  /// [volume] is 0.0–1.0 (mapped to player units in implementation).
  Future<void> setVolumeNormalized(double volume);

  Future<void> playOrPause();

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  /// Encoded frame capture (`image/jpeg`, `image/png`, or raw when [format] is null).
  Future<Uint8List?> screenshot({String? format});

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
  Future<void> disableRenderedSubtitles() =>
      _player.setSubtitleTrack(mk.SubtitleTrack.no());

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
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<Uint8List?> screenshot({String? format}) =>
      _player.screenshot(format: format);

  @override
  Future<void> dispose() => _player.dispose();
}
