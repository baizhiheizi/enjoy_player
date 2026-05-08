/// Plays shadow-reading `.wav` takes without NuGet-dependent Windows plugins.
///
/// - **Windows**: `winmm.dll` `PlaySoundW` (FFI; no `audioplayers_windows`).
/// - **Linux**: `paplay` or `aplay`.
/// - **macOS / iOS / Android**: `just_audio` (no Windows implementation; not used on Windows).
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('shadowRecordingPlayback');

AudioPlayer? _justAudioPreview;

/// Plays a local WAV file for the shadow-reading panel.
Future<void> playShadowRecordingFile(String path) async {
  if (kIsWeb) {
    throw UnsupportedError('Shadow recording playback is not available on web.');
  }
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Recording file missing: $path');
  }
  final absolute = file.absolute.path;

  if (Platform.isWindows) {
    _playWindowsPlaySound(absolute);
    return;
  }
  if (Platform.isLinux) {
    await _playLinuxPulseOrAlsa(absolute);
    return;
  }

  await _playJustAudio(absolute);
}

void _playWindowsPlaySound(String absolutePath) {
  final winmm = DynamicLibrary.open('winmm.dll');
  final playSound = winmm.lookupFunction<
      Int32 Function(Pointer<Utf16>, Pointer<Void>, Uint32),
      int Function(Pointer<Utf16>, Pointer<Void>, int)>('PlaySoundW');

  const sndAsync = 0x0001;
  const sndNoDefault = 0x0002;
  const sndFilename = 0x00020000;

  final psz = absolutePath.toNativeUtf16();
  try {
    playSound(psz, nullptr, sndAsync | sndFilename | sndNoDefault);
  } finally {
    malloc.free(psz);
  }
}

Future<void> _playLinuxPulseOrAlsa(String absolutePath) async {
  final paplay = await Process.run('paplay', [absolutePath]);
  if (paplay.exitCode == 0) return;

  final aplay = await Process.run('aplay', [absolutePath]);
  if (aplay.exitCode == 0) return;

  throw StateError(
    'Neither paplay nor aplay could play the file '
    '(paplay: ${paplay.stderr}; aplay: ${aplay.stderr})',
  );
}

Future<void> _playJustAudio(String absolutePath) async {
  try {
    _justAudioPreview ??= AudioPlayer();
    await _justAudioPreview!.stop();
    await _justAudioPreview!.setFilePath(absolutePath);
    await _justAudioPreview!.play();
  } catch (e, st) {
    _log.warning('just_audio preview failed', e, st);
    rethrow;
  }
}
