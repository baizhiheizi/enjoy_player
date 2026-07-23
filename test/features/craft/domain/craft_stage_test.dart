import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/craft/domain/craft_stage.dart';

void main() {
  test('CraftStage has exactly four values in order', () {
    expect(CraftStage.values.length, 4);
    expect(CraftStage.values, [
      CraftStage.capture,
      CraftStage.rewrite,
      CraftStage.audio,
      CraftStage.done,
    ]);
  });

  test('capture is the first (default) value', () {
    expect(CraftStage.values.first, CraftStage.capture);
  });

  test('name property is correct', () {
    expect(CraftStage.capture.name, 'capture');
    expect(CraftStage.rewrite.name, 'rewrite');
    expect(CraftStage.audio.name, 'audio');
    expect(CraftStage.done.name, 'done');
  });
}
