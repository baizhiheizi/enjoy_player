/// Per-media listening-focus (transcript blur) practice mode.
///
/// Mirrors [EchoMode]: in-memory `keepAlive` state restored from
/// `echo_sessions.blur_active` on media open and cleared on player dismiss.
/// Not a global Settings preference.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transcript_blur_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class TranscriptBlurMode extends _$TranscriptBlurMode {
  @override
  bool build() => false;

  void activate() {
    if (state) return;
    state = true;
  }

  void deactivate() {
    if (!state) return;
    state = false;
  }

  void toggle() {
    state = !state;
  }

  void restoreFromSession(bool blurActive) {
    state = blurActive;
  }
}
