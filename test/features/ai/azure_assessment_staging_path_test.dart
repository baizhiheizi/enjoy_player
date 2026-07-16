import 'package:enjoy_player/features/ai/data/azure_assessment_staging_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('pathContainsNonAscii', () {
    test('false for ASCII-only paths', () {
      expect(
        pathContainsNonAscii(r'C:\Users\alice\AppData\Local\Temp'),
        isFalse,
      );
      expect(pathContainsNonAscii('/tmp/azure_assess.wav'), isFalse);
    });

    test('true when path has non-ASCII characters', () {
      expect(pathContainsNonAscii(r'C:\Users\尚彬彬\AppData\Local\Temp'), isTrue);
    });
  });

  group('preferAsciiTempRoot', () {
    test('returns systemTemp when not Windows', () {
      expect(
        preferAsciiTempRoot(
          isWindows: false,
          systemTemp: r'C:\Users\尚彬彬\Temp',
          systemRoot: r'C:\Windows',
        ),
        r'C:\Users\尚彬彬\Temp',
      );
    });

    test('returns systemTemp when already ASCII', () {
      expect(
        preferAsciiTempRoot(
          isWindows: true,
          systemTemp: r'C:\Users\alice\AppData\Local\Temp',
          systemRoot: r'C:\Windows',
        ),
        r'C:\Users\alice\AppData\Local\Temp',
      );
    });

    test(
      'prefers SystemRoot\\Temp\\EnjoyPlayer when systemTemp is non-ASCII',
      () {
        expect(
          preferAsciiTempRoot(
            isWindows: true,
            systemTemp: r'C:\Users\尚彬彬\AppData\Local\Temp',
            systemRoot: r'C:\Windows',
          ),
          p.join(r'C:\Windows', 'Temp', 'EnjoyPlayer'),
        );
      },
    );

    test('falls back to WINDIR then C:\\Windows\\Temp\\EnjoyPlayer', () {
      expect(
        preferAsciiTempRoot(
          isWindows: true,
          systemTemp: r'C:\Users\尚彬彬\Temp',
          systemRoot: null,
          windir: r'C:\Windows',
        ),
        p.join(r'C:\Windows', 'Temp', 'EnjoyPlayer'),
      );
      expect(
        preferAsciiTempRoot(
          isWindows: true,
          systemTemp: r'C:\Users\尚彬彬\Temp',
          systemRoot: null,
          windir: null,
        ),
        p.join(r'C:\Windows', 'Temp', 'EnjoyPlayer'),
      );
    });
  });
}
