/// Format [Duration] as `mm:ss` or `h:mm:ss` with zero-padded segments (player UI).
library;

String formatDurationHms(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

/// Alias for [formatDurationHms] (legacy name).
String formatDuration(Duration d) => formatDurationHms(d);

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
