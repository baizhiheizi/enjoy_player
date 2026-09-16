import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticLogConfig integration', () {
    setUp(() {
      DiagnosticLogConfig.setVerboseEnabled(false);
    });

    test('setVerboseEnabled updates the global flag', () {
      DiagnosticLogConfig.setVerboseEnabled(true);
      expect(DiagnosticLogConfig.verboseEnabled, isTrue);
      DiagnosticLogConfig.setVerboseEnabled(false);
      expect(DiagnosticLogConfig.verboseEnabled, isFalse);
    });
  });
}
