import 'dart:convert';

import 'package:meta/meta.dart';

import 'native_paths.dart';

bool? _ffiAvailableOverride;

/// Test harness: force [espeakFfiIsAvailable] without touching native files.
@visibleForTesting
void debugSetEspeakFfiAvailable(bool? value) {
  _ffiAvailableOverride = value;
}

/// True when the test harness forced the native library unavailable.
@internal
bool get espeakFfiForcedUnavailable => _ffiAvailableOverride == false;

/// Decodes eSpeak `id.string[8]` IPA bytes (UTF-8 with `espeakINITIALIZE_PHONEME_IPA`).
///
/// Must not use [String.fromCharCodes] on the raw bytes — that Latin-1-style
/// decode turns multi-byte IPA (e.g. `ɡ` `C9 A1`) into mojibake (`É¡`).
String decodeEspeakPhonemeIdBytes(List<int> units) {
  if (units.isEmpty) return '';
  return utf8.decode(units, allowMalformed: true);
}

/// True when a vendored eSpeak-NG library and data directory can be opened.
bool espeakFfiIsAvailable() {
  if (_ffiAvailableOverride != null) return _ffiAvailableOverride!;
  try {
    return resolveEspeakLibraryPath() != null &&
        resolveEspeakDataPath() != null;
  } catch (_) {
    return false;
  }
}
