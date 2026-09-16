/// media_kit playback engine for local files and generic HTTP(S) (ADR-0003).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/data/files/security_scoped_bookmark.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

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
///
/// The native mpv player is constructed lazily on first access (not in the
/// constructor) so swapping between YouTube and local media does not stall the
/// main isolate with an unnecessary native allocation (issue #283, P8).
class MediaKitPlayerEngine implements PlayerEngine {
  MediaKitPlayerEngine();

  mk.Player? __player;

  /// Set by [prepareNativeBackend] after the previous platform view has
  /// detached. Only the video stage consults it (via [nativeBackendAllowed]):
  /// the stream/snapshot getters read `__player` without ever constructing,
  /// and the command path ([_player]) allocates mpv unconditionally — the
  /// WebView-detach wait lives in the swap (player_engine_binding), not in a
  /// getter (2026-08-30 field report, issue #658).
  var _nativeBackendAllowed = false;

  /// Whether [prepareNativeBackend] has approved native allocation. Read by
  /// the MediaKit video stage (`presentation/widgets/media_kit_video_stage.dart`)
  /// so it mounts a plain black placeholder — never a [VideoController] —
  /// until the previous engine's WebView has detached.
  bool get nativeBackendAllowed => _nativeBackendAllowed;

  mk.Player get _player => __player ??= mk.Player();

  mk.Player get player => _player;

  /// Handle for the currently-held macOS security-scoped resource grant, if
  /// any. Owned by this engine and paired with [releaseBookmark] before the
  /// next `open()` or on `dispose()`. See ADR-0060.
  int? _scopeToken;

  VideoController? _videoController;

  static VideoControllerConfiguration get _videoControllerConfiguration {
    if (Platform.isAndroid || Platform.isIOS) {
      return const VideoControllerConfiguration();
    }
    // Desktop: software output. HW textures can stay black until a later
    // Flutter layout (Windows D3D, macOS OpenGL, Linux EGL — ADR-0048).
    return const VideoControllerConfiguration(
      width: kVideoControllerWidth,
      height: kVideoControllerHeight,
      hwdec: 'auto-safe',
      enableHardwareAcceleration: false,
    );
  }

  VideoController get videoController {
    return _videoController ??= VideoController(
      _player,
      configuration: _videoControllerConfiguration,
    );
  }

  @override
  Stream<Duration> get position =>
      __player?.stream.position ?? const Stream<Duration>.empty();

  /// [_player.stream.duration] is a broadcast stream that does not replay.
  /// [PlayerController] subscribes after `open` + other awaits, so the first
  /// duration event can be missed on Android. Seed from [_player.state.duration].
  @override
  Stream<Duration> get duration {
    final player = __player;
    if (player == null) return const Stream<Duration>.empty();
    return Stream.multi((controller) {
      final current = player.state.duration;
      if (current > Duration.zero) {
        controller.add(current);
      }
      final sub = player.stream.duration.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<bool> get playing =>
      __player?.stream.playing ?? const Stream<bool>.empty();

  @override
  Stream<bool> get buffering =>
      __player?.stream.buffering ?? const Stream<bool>.empty();

  @override
  Stream<void> get completed =>
      __player?.stream.completed ?? const Stream<void>.empty();

  @override
  Stream<mk.Tracks>? get mkTracksStream => __player?.stream.tracks;

  @override
  bool get supportsVideoPosterCapture => true;

  @override
  bool get supportsSubtitleDisabling => true;

  @override
  bool get supportsYouTubePlayback => false;

  @override
  Future<void> awaitSurfaceReady() async {}

  @override
  Future<void> awaitSurfaceDetached() async {}

  @override
  void prepareNativeBackend() {
    _nativeBackendAllowed = true;
  }

  /// No metadata capability: MediaKit renders decoded frames directly, so
  /// there is no loading poster, no source identity, and no init timing.
  @override
  PlayerEngineMetadata? get metadata => null;

  @override
  void resetCompletionFlag() {}

  @override
  Future<void> teardownAfterClear({required bool keepSurfaceMounted}) => stop();

  @override
  ({bool playing, bool buffering}) get transportSnapshot {
    final player = __player;
    if (player == null) {
      return (playing: false, buffering: false);
    }
    return (playing: player.state.playing, buffering: player.state.buffering);
  }

  @override
  bool get keepSurfaceWhenParked => false;

  @override
  Future<void> open(PlayableSource source) async {
    final uri = switch (source) {
      LocalFilePlayableSource(:final uri) => uri,
      RemoteUrlPlayableSource(:final uri) => uri,
      YoutubePlayableSource() => throw UnsupportedError(
        'MediaKitPlayerEngine cannot open YouTube',
      ),
    };
    // Release any prior scope before we open the new source — libmpv will
    // read from the URL immediately, so the grant must cover the new path.
    final previousToken = _scopeToken;
    if (previousToken != null) {
      _scopeToken = null;
      await SecurityScopedBookmarkChannel.releaseBookmark(previousToken);
    }
    if (source is LocalFilePlayableSource) {
      _scopeToken = source.scopeToken;
    }
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
      _player.setVolume(volume.clamp(0, 1) * kVolumeScale);

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
    // Do not construct [VideoController] here. media_kit binds the native
    // texture one frame after [VideoController] is created; if that happens
    // with no [Video] widget mounted, Windows/Android stay black until a later
    // layout. The MediaKit video stage creates the controller on first
    // build.
  }

  @override
  Future<void> dispose() async {
    final token = _scopeToken;
    if (token != null) {
      _scopeToken = null;
      await SecurityScopedBookmarkChannel.releaseBookmark(token);
    }
    await __player?.dispose();
    __player = null;
  }
}
