/// Dedicated [media_kit.Player] for shadow-reading take previews (ADR-0003 scope).
///
/// Separate from [PlayerController]'s engine so lesson playback is not replaced.
///
/// [stop] clears the loaded file path; [play] / [playOrPauseTake] set it after a
/// successful [open].
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('recordingPreview');

/// Wraps a single `media_kit` player for local WAV (or other) preview files.
class RecordingPreviewPlayer {
  RecordingPreviewPlayer() : _player = mk.Player();

  final mk.Player _player;
  bool _disposed = false;

  /// Absolute path of the file last opened for preview, or null after [stop].
  String? _loadedPath;

  /// Absolute path of the media currently loaded, if any.
  String? get loadedPath => _loadedPath;

  Stream<Duration> get position => _player.stream.position;

  Stream<Duration> get duration => _player.stream.duration;

  Stream<bool> get playing => _player.stream.playing;

  /// Plays [path] from disk; stops any current preview first.
  Future<void> play(String path) async {
    if (_disposed) {
      throw StateError('RecordingPreviewPlayer disposed');
    }
    if (kIsWeb) {
      throw UnsupportedError(
        'Shadow recording playback is not available on web.',
      );
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Recording file missing: $path');
    }
    final uri = Uri.file(file.absolute.path).toString();
    try {
      await stop();
      await _player.open(mk.Media(uri));
      await _player.play();
      _loadedPath = file.absolute.path;
    } catch (e, st) {
      _log.warning('preview playback failed', e, st);
      rethrow;
    }
  }

  /// If [path] is already loaded, toggles play/pause; otherwise opens and plays it.
  Future<void> playOrPauseTake(String path) async {
    if (_disposed) {
      throw StateError('RecordingPreviewPlayer disposed');
    }
    if (kIsWeb) {
      throw UnsupportedError(
        'Shadow recording playback is not available on web.',
      );
    }
    final abs = File(path).absolute.path;
    if (_loadedPath != null && _loadedPath == abs) {
      await _player.playOrPause();
      return;
    }
    await play(path);
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _player.stop();
    _loadedPath = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loadedPath = null;
    await _player.dispose();
  }
}
