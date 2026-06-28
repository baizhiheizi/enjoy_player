/// Abstraction over playback backends: [MediaKitPlayerEngine] (default) and [YouTubePlayerEngine].
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/features/player/domain/playable_source.dart';

/// Contract implemented by [MediaKitPlayerEngine] / [YouTubePlayerEngine]; fakes in tests.
abstract class PlayerEngine {
  Stream<Duration> get position;

  Stream<Duration> get duration;

  Stream<bool> get playing;

  Stream<bool> get buffering;

  /// libmpv / media_kit subtitle tracks; `null` when unsupported (e.g. WebView).
  Stream<mk.Tracks>? get mkTracksStream;

  /// Whether [screenshot] can produce stored video thumbnails (false for WebView).
  bool get supportsVideoPosterCapture;

  /// Whether [disableRenderedSubtitles] does anything. YouTube / WebView
  /// engines have no embedded subtitle track to disable.
  bool get supportsSubtitleDisabling;

  /// Current transport flags for seeding [StreamProvider]s.
  ({bool playing, bool buffering}) get transportSnapshot;

  /// Display aspect ratio for letterboxing (width / height).
  Stream<double> get videoAspectRatioStream;

  Widget buildVideoStage({
    required BuildContext context,
    required double maxWidth,
    required double maxHeight,
  });

  Future<void> open(PlayableSource source);

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

  /// Ensures video texture binding before decode on Windows (media_kit only).
  void warmVideoSurface();

  Future<void> dispose();
}

double aspectRatioFromVideoParams(mk.VideoParams vp, mk.PlayerState state) {
  if (vp.aspect != null && vp.aspect! > 0) {
    return vp.aspect!;
  }
  final ww = vp.dw ?? vp.w ?? state.width;
  final hh = vp.dh ?? vp.h ?? state.height;
  if (ww != null && hh != null && ww > 0 && hh > 0) {
    return ww / hh;
  }
  return 16 / 9;
}

/// Single [mk.Player] instance — ADR-0003 / ADR-0015.
class MediaKitPlayerEngine implements PlayerEngine {
  MediaKitPlayerEngine() : _player = mk.Player();

  final mk.Player _player;
  VideoController? _videoController;

  mk.Player get player => _player;

  static VideoControllerConfiguration get _videoControllerConfiguration {
    if (Platform.isWindows) {
      return const VideoControllerConfiguration(width: 1920, height: 1080);
    }
    if (Platform.isMacOS) {
      // Bind libmpv video output before decode; prefer software GL texture path
      // on recent macOS where deprecated OpenGL HW textures can stay black.
      return const VideoControllerConfiguration(
        width: 1920,
        height: 1080,
        hwdec: 'auto-safe',
        enableHardwareAcceleration: false,
      );
    }
    return const VideoControllerConfiguration();
  }

  VideoController get videoController {
    return _videoController ??= VideoController(
      _player,
      configuration: _videoControllerConfiguration,
    );
  }

  @override
  Stream<Duration> get position => _player.stream.position;

  /// [_player.stream.duration] is a broadcast stream that does not replay.
  /// [PlayerController] subscribes after `open` + other awaits, so the first
  /// duration event can be missed on Android. Seed from [_player.state.duration].
  @override
  Stream<Duration> get duration {
    return Stream.multi((controller) {
      final current = _player.state.duration;
      if (current > Duration.zero) {
        controller.add(current);
      }
      final sub = _player.stream.duration.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get buffering => _player.stream.buffering;

  @override
  Stream<mk.Tracks>? get mkTracksStream => _player.stream.tracks;

  @override
  bool get supportsVideoPosterCapture => true;

  @override
  bool get supportsSubtitleDisabling => true;

  @override
  ({bool playing, bool buffering}) get transportSnapshot =>
      (playing: _player.state.playing, buffering: _player.state.buffering);

  @override
  Stream<double> get videoAspectRatioStream => _player.stream.videoParams
      .map((vp) => aspectRatioFromVideoParams(vp, _player.state))
      .distinct((a, b) => (a - b).abs() < 0.0001);

  @override
  Widget buildVideoStage({
    required BuildContext context,
    required double maxWidth,
    required double maxHeight,
  }) {
    final controller = videoController;
    if (maxWidth <= 0 || maxHeight <= 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<double>(
      stream: videoAspectRatioStream,
      initialData: aspectRatioFromVideoParams(
        _player.state.videoParams,
        _player.state,
      ),
      builder: (context, snapshot) {
        final ar = (snapshot.data ?? (16 / 9)).clamp(0.001, 1000.0);
        final w = maxWidth;
        final h = w / ar;

        return ClipRect(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: w,
              height: h,
              child: ExcludeSemantics(
                child: Video(
                  controller: controller,
                  controls: null,
                  width: w,
                  height: h,
                  fit: BoxFit.contain,
                  fill: Colors.black,
                  subtitleViewConfiguration: const SubtitleViewConfiguration(
                    visible: false,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> open(PlayableSource source) async {
    final uri = switch (source) {
      LocalFilePlayableSource(:final uri) => uri,
      RemoteUrlPlayableSource(:final uri) => uri,
      YoutubePlayableSource() => throw UnsupportedError(
        'MediaKitPlayerEngine cannot open YouTube',
      ),
    };
    await _player.open(mk.Media(uri));
  }

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
  void warmVideoSurface() {
    if (Platform.isWindows || Platform.isMacOS) {
      videoController;
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
