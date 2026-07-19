import 'package:enjoy_player/features/hotkeys/application/shadow_reading_hotkey_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shadowReadingBusHotkeysEnabled', () {
    test('true with an active player session', () {
      expect(
        shadowReadingBusHotkeysEnabled(
          hasPlayerSession: true,
          vocabularyEchoPracticeOpen: false,
        ),
        isTrue,
      );
    });

    test('true during vocabulary echo practice without a player session', () {
      expect(
        shadowReadingBusHotkeysEnabled(
          hasPlayerSession: false,
          vocabularyEchoPracticeOpen: true,
        ),
        isTrue,
      );
    });

    test('false when neither player session nor vocabulary echo is open', () {
      expect(
        shadowReadingBusHotkeysEnabled(
          hasPlayerSession: false,
          vocabularyEchoPracticeOpen: false,
        ),
        isFalse,
      );
    });
  });
}
