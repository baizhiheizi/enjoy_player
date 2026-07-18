import 'package:enjoy_player/core/utils/client_timezone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatUtcOffset', () {
    test('formats positive whole-hour offsets', () {
      expect(formatUtcOffset(const Duration(hours: 8)), '+08:00');
      expect(formatUtcOffset(Duration.zero), '+00:00');
    });

    test('formats negative offsets', () {
      expect(formatUtcOffset(const Duration(hours: -5)), '-05:00');
    });

    test('includes non-zero minutes', () {
      expect(formatUtcOffset(const Duration(hours: 5, minutes: 30)), '+05:30');
      expect(
        formatUtcOffset(const Duration(hours: -9, minutes: -30)),
        '-09:30',
      );
    });
  });

  group('clientTimezoneId', () {
    test('returns a non-empty IANA id or UTC offset', () async {
      final id = await clientTimezoneId();
      expect(id, isNotEmpty);
      // Either IANA (contains '/') or ±HH:MM offset fallback.
      final isIana = id.contains('/');
      final isOffset = RegExp(r'^[+-]\d{2}:\d{2}$').hasMatch(id);
      expect(isIana || isOffset, isTrue, reason: 'unexpected timezone: $id');
    });
  });
}
