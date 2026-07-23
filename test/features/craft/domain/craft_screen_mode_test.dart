import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';

void main() {
  test('CraftScreenMode has exactly two values', () {
    expect(CraftScreenMode.values.length, 2);
  });

  test('express is the first (default) value', () {
    expect(CraftScreenMode.values.first, CraftScreenMode.express);
  });

  test('advanced is the second value', () {
    expect(CraftScreenMode.values[1], CraftScreenMode.advanced);
  });

  test('name property is correct', () {
    expect(CraftScreenMode.express.name, 'express');
    expect(CraftScreenMode.advanced.name, 'advanced');
  });
}
