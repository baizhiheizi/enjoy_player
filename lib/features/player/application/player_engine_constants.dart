/// Tuning constants for [MediaKitPlayerEngine] video controller dimensions,
/// aspect-ratio dedup epsilon, and normalised-volume mapping.
library;

/// Default width for the [media_kit] [VideoController] on non-mobile platforms.
const int kVideoControllerWidth = 1920;

/// Default height for the [media_kit] [VideoController] on non-mobile platforms.
const int kVideoControllerHeight = 1080;

/// Two aspect ratios within this epsilon are considered equal (dedup guard for
/// the [MediaKitPlayerEngine.videoAspectRatioStream]).
const double kAspectRatioEpsilon = 0.0001;

/// Scale factor mapping a 0.0–1.0 normalised volume to `media_kit` volume units.
const double kVolumeScale = 100;
