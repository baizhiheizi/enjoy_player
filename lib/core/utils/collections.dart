/// Small collection helpers shared across features.
library;

/// Element-wise equality for two lists using each element's `==`.
///
/// Prefer this over ad-hoc `_listEqualsX` helpers so stream dedupe sites share
/// one implementation. Returns `true` when [identical], otherwise compares
/// length then each index.
bool listEquals<T>(List<T> previous, List<T> current) {
  if (identical(previous, current)) return true;
  if (previous.length != current.length) return false;
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != current[i]) return false;
  }
  return true;
}
