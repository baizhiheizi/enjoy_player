/// The low-credits line shared by every meter and chip.
library;

/// At or above this fraction of the daily pool used, the UI warns
/// (profile credits meter, lookup sheet credits chip).
const double kLowCreditsUsedFraction = 0.9;

/// Fraction of the daily pool consumed, clamped to [0, 1]; 0 when the
/// usage is unknown or the pool is empty.
double creditsUsedFraction({required int? used, required int limit}) {
  if (used == null || limit <= 0) return 0.0;
  return (used / limit).clamp(0.0, 1.0);
}

/// True when the consumed fraction reaches [kLowCreditsUsedFraction].
bool creditsLow({required int? used, required int limit}) =>
    creditsUsedFraction(used: used, limit: limit) >= kLowCreditsUsedFraction;
