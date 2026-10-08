/// Format [Duration] as `m:ss` or `h:mm:ss` (player UI; the Duet boards' clock style).
library;

String formatDurationHms(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '$h:${two(m)}:${two(s)}';
  return '$m:${two(s)}';
}

/// Player-style `m:ss` / `h:mm:ss` from a millisecond duration.
String formatDurationHmsMs(int milliseconds) =>
    formatDurationHms(Duration(milliseconds: milliseconds));

/// Player-style `m:ss` / `h:mm:ss` from a (possibly fractional) second count.
///
/// Fractional seconds are rounded to the nearest millisecond before formatting
/// so transport chrome and library tiles stay consistent.
String formatDurationHmsSeconds(num seconds) =>
    formatDurationHmsMs((seconds * 1000).round());

/// Compact human-readable practice duration (`15m 30s`, `2h 5m`, `45s`).
String formatPracticeDurationMs(int ms) {
  if (ms <= 0) return '0m';
  final seconds = ms ~/ 1000;
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes % 60}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds % 60}s';
  }
  return '${seconds}s';
}
