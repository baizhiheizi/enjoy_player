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
