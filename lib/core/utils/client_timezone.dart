/// Client timezone helpers for API "today" stats (IANA id preferred).
library;

import 'package:flutter_timezone/flutter_timezone.dart';

/// Formats a UTC offset as `±HH:MM` (e.g. `+08:00`, `-05:00`).
///
/// Rails [Time.find_zone] accepts this form when an IANA id is unavailable.
String formatUtcOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes >= 0 ? '+' : '-';
  final abs = totalMinutes.abs();
  final hours = abs ~/ 60;
  final minutes = abs % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return '$sign${two(hours)}:${two(minutes)}';
}

/// Returns the device IANA timezone id (e.g. `Asia/Shanghai`).
///
/// Falls back to a UTC offset string if the native plugin fails, so Rails can
/// still localize "today" instead of silently using server UTC.
Future<String> clientTimezoneId() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    final id = info.identifier.trim();
    if (id.isNotEmpty) return id;
  } catch (_) {
    // Method channel unavailable in tests / rare platform failures.
  }
  return formatUtcOffset(DateTime.now().timeZoneOffset);
}
