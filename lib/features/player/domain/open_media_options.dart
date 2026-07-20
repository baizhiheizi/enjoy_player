/// Options for [PlayerController.openMedia] beyond the default session restore.
library;

/// Controls whether a new open restores persisted playback position / echo.
final class OpenMediaOptions {
  const OpenMediaOptions({
    this.restorePosition = true,
    this.restoreEcho = true,
  });

  /// When false, skip seeking to the last persisted position.
  final bool restorePosition;

  /// When false, leave echo inactive after open (caller may activate a window).
  final bool restoreEcho;

  /// Vocabulary clip / explicit launch: ignore lesson resume state.
  static const OpenMediaOptions explicitLaunch = OpenMediaOptions(
    restorePosition: false,
    restoreEcho: false,
  );

  static const OpenMediaOptions defaults = OpenMediaOptions();
}
