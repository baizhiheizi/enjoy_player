import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transcriptActiveIndexForEchoUi', () {
    test('filters to echo window', () {
      final echo = const EchoState(
        active: true,
        startLineIndex: 1,
        endLineIndex: 2,
        startTimeSeconds: 0,
        endTimeSeconds: 10,
      );
      expect(transcriptActiveIndexForEchoUi(echo, 0), -1);
      expect(transcriptActiveIndexForEchoUi(echo, 1), 1);
      expect(transcriptActiveIndexForEchoUi(echo, 3), -1);
    });
  });
}
