/// Ephemeral practice mode for vocabulary flashcard review.
library;

/// Which practice surface the shared review practice sheet should show.
enum ReviewPracticeMode {
  /// No practice sheet / idle.
  none,

  /// Clip mini-player in the practice sheet.
  clip,

  /// Echo recorder in the practice sheet.
  echo,
}

/// Fine-grained clip pipeline phase (portal attach + playback).
enum ReviewPracticePhase {
  /// No practice UI.
  none,

  /// Clip overlay open; media resolving / engine swap in flight.
  clipOpening,

  /// Clip overlay open; surface target attached and playback ready.
  clipReady,

  /// Echo recorder overlay (no video surface claim).
  echo,
}

extension ReviewPracticePhaseX on ReviewPracticePhase {
  bool get isClip =>
      this == ReviewPracticePhase.clipOpening ||
      this == ReviewPracticePhase.clipReady;

  bool get overlayOpen => this != ReviewPracticePhase.none;

  bool get claimsVideoSurface => this == ReviewPracticePhase.clipReady;

  ReviewPracticeMode get asMode => switch (this) {
    ReviewPracticePhase.none => ReviewPracticeMode.none,
    ReviewPracticePhase.clipOpening ||
    ReviewPracticePhase.clipReady => ReviewPracticeMode.clip,
    ReviewPracticePhase.echo => ReviewPracticeMode.echo,
  };
}

extension ReviewPracticeModeX on ReviewPracticeMode {
  ReviewPracticePhase toPhase() => switch (this) {
    ReviewPracticeMode.none => ReviewPracticePhase.none,
    ReviewPracticeMode.clip => ReviewPracticePhase.clipReady,
    ReviewPracticeMode.echo => ReviewPracticePhase.echo,
  };
}
