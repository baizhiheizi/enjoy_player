import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/craft/domain/craft_solid_transcript_hint_gate.dart';

void main() {
  setUp(CraftSolidTranscriptHintGate.resetForTests);

  test('consume shows once then suppresses for the session', () {
    expect(CraftSolidTranscriptHintGate.shownThisSession, isFalse);
    expect(CraftSolidTranscriptHintGate.consume(), isTrue);
    expect(CraftSolidTranscriptHintGate.shownThisSession, isTrue);
    expect(CraftSolidTranscriptHintGate.consume(), isFalse);
    expect(CraftSolidTranscriptHintGate.consume(), isFalse);
  });

  test('resetForTests allows consume again', () {
    expect(CraftSolidTranscriptHintGate.consume(), isTrue);
    CraftSolidTranscriptHintGate.resetForTests();
    expect(CraftSolidTranscriptHintGate.consume(), isTrue);
  });
}
