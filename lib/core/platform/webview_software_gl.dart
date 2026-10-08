/// Software-GL fallback for the Linux embedded-browser texture pipeline
/// (specs/047 T047 / ADR-0092).
///
/// On some GPU driver + compositor stacks WPE's hardware frame export delivers
/// zero frames to Flutter while the page itself runs fine; `LIBGL_ALWAYS_SOFTWARE`
/// set in the launcher process (inherited by WebKit's helper processes) makes
/// the whole pipeline render and export correctly. Only contexts created after
/// the flag is set are affected — existing GL contexts keep their backend.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('WebViewSoftwareGl');

/// Environment variable consulted by Mesa at GL context creation.
const softwareGlEnvKey = 'LIBGL_ALWAYS_SOFTWARE';

bool _applied = false;

/// True once [enableSoftwareGlForNewContexts] has set the flag in this
/// process; the player uses it as the once-per-session guard.
bool get softwareGlForcedForNewContexts => _applied;

/// Sets [softwareGlEnvKey] for this process and every helper process spawned
/// from it afterwards. Idempotent; never throws.
bool enableSoftwareGlForNewContexts() {
  if (_applied) return true;
  try {
    final libc = DynamicLibrary.process();
    final setenv = libc
        .lookupFunction<
          Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Int32),
          int Function(Pointer<Uint8>, Pointer<Uint8>, int)
        >('setenv');
    final key = softwareGlEnvKey.toNativeUtf8().cast<Uint8>();
    final value = '1'.toNativeUtf8().cast<Uint8>();
    final rc = setenv(key, value, 1);
    calloc.free(key);
    calloc.free(value);
    if (rc != 0) {
      _log.warning('setenv($softwareGlEnvKey) failed rc=$rc');
      return false;
    }
    _applied = true;
    _log.info('software GL enabled for newly created GL contexts');
    return true;
  } on Object catch (e, st) {
    _log.warning('software GL fallback unavailable', e, st);
    return false;
  }
}

/// Test seam: clears the applied flag so a later call re-runs setenv.
void debugResetSoftwareGlForTesting() {
  _applied = false;
}
