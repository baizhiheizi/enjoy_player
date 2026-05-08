/// Tick-based intents from global hotkeys → shadow-reading widgets (recording / pitch / assessment).
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shadow_reading_hotkey_bus.g.dart';

@immutable
class ShadowReadingHotkeyTicks {
  const ShadowReadingHotkeyTicks({
    required this.recording,
    required this.playback,
    required this.pitchContour,
    required this.assessment,
  });

  final int recording;
  final int playback;
  final int pitchContour;
  final int assessment;

  static const initial = ShadowReadingHotkeyTicks(
    recording: 0,
    playback: 0,
    pitchContour: 0,
    assessment: 0,
  );

  ShadowReadingHotkeyTicks copyWith({
    int? recording,
    int? playback,
    int? pitchContour,
    int? assessment,
  }) {
    return ShadowReadingHotkeyTicks(
      recording: recording ?? this.recording,
      playback: playback ?? this.playback,
      pitchContour: pitchContour ?? this.pitchContour,
      assessment: assessment ?? this.assessment,
    );
  }
}

@Riverpod(keepAlive: true)
class ShadowReadingHotkeyBus extends _$ShadowReadingHotkeyBus {
  @override
  ShadowReadingHotkeyTicks build() => ShadowReadingHotkeyTicks.initial;

  void pulseRecording() {
    state = state.copyWith(recording: state.recording + 1);
  }

  void pulsePlayback() {
    state = state.copyWith(playback: state.playback + 1);
  }

  void pulsePitchContour() {
    state = state.copyWith(pitchContour: state.pitchContour + 1);
  }

  void pulseAssessment() {
    state = state.copyWith(assessment: state.assessment + 1);
  }
}
