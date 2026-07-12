/// Canonical HH:MM:SS(.mmm) → [Duration] parser used by subtitle parsers
/// and ffmpeg probe output. Accepts both `.` and `,` as the sub-second
/// separator (SRT uses comma).
library;

/// Parses `HH:MM:SS` or `HH:MM:SS.mmm` into a [Duration].
/// Returns `null` on malformed input.
///
/// Accepts both `.` and `,` as the sub-second separator (SRT uses comma).
/// Fractional seconds shorter than 3 digits are right-padded to
/// milliseconds; longer fractions are truncated to 3 digits.
Duration? tryParseHmsDuration(String input) {
  final normalized = input.replaceAll(',', '.');
  final parts = normalized.split(':');
  if (parts.length < 2 || parts.length > 3) return null;

  final hasHours = parts.length == 3;
  final h = hasHours ? (int.tryParse(parts[0]) ?? 0) : 0;
  final m = int.tryParse(parts[hasHours ? 1 : 0]) ?? 0;
  final secParts = parts[hasHours ? 2 : 1].split('.');
  final s = int.tryParse(secParts[0]) ?? 0;
  var ms = 0;
  if (secParts.length > 1) {
    final frac = secParts[1];
    ms = int.tryParse(frac.padRight(3, '0').substring(0, 3)) ?? 0;
  }

  if (h < 0 || m < 0 || m > 59 || s < 0 || s > 59) return null;

  return Duration(hours: h, minutes: m, seconds: s, milliseconds: ms);
}
