/// Semantic version comparison (UI-free).
library;

/// Parses `major.minor.patch` optionally prefixed with `v`.
List<int>? parseSemver(String raw) {
  final trimmed = raw.trim().replaceFirst(RegExp(r'^v'), '');
  final core = trimmed.split('+').first.split('-').first;
  final parts = core.split('.');
  if (parts.length < 2 || parts.length > 3) return null;
  final nums = <int>[];
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null || n < 0) return null;
    nums.add(n);
  }
  while (nums.length < 3) {
    nums.add(0);
  }
  return nums;
}

/// Negative if [a] < [b], zero if equal, positive if [a] > [b].
int compareSemver(String a, String b) {
  final pa = parseSemver(a);
  final pb = parseSemver(b);
  if (pa == null || pb == null) {
    return a == b ? 0 : a.compareTo(b);
  }
  for (var i = 0; i < 3; i++) {
    final d = pa[i] - pb[i];
    if (d != 0) return d;
  }
  return 0;
}

bool isVersionLessThan(String current, String other) =>
    compareSemver(current, other) < 0;

bool isVersionLessThanOrEqual(String current, String other) =>
    compareSemver(current, other) <= 0;
