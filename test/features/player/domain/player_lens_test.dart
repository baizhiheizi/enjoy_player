import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/player/domain/player_lens.dart';

void main() {
  test('no mode on reads as Listen', () {
    expect(
      playerLensFrom(echoActive: false, hideText: false),
      PlayerLens.listen,
    );
  });

  test('hide text alone reads as Dictate', () {
    expect(
      playerLensFrom(echoActive: false, hideText: true),
      PlayerLens.dictate,
    );
  });

  test('Echo wins when a legacy session restored both flags', () {
    expect(playerLensFrom(echoActive: true, hideText: true), PlayerLens.echo);
    expect(playerLensFrom(echoActive: true, hideText: false), PlayerLens.echo);
  });
}
