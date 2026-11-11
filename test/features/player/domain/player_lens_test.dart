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

  test(
    'Dictate takes precedence when both echoActive and hideText are active',
    () {
      expect(
        playerLensFrom(echoActive: true, hideText: true),
        PlayerLens.dictate,
      );
      expect(
        playerLensFrom(echoActive: true, hideText: false),
        PlayerLens.echo,
      );
    },
  );

  test('PlayerLens helpers report correct mode flags', () {
    expect(PlayerLens.listen.loopMode, isFalse);
    expect(PlayerLens.listen.dictationMode, isFalse);
    expect(PlayerLens.listen.blurMode, isFalse);

    expect(PlayerLens.echo.loopMode, isTrue);
    expect(PlayerLens.echo.dictationMode, isFalse);
    expect(PlayerLens.echo.blurMode, isFalse);

    expect(PlayerLens.dictate.loopMode, isTrue);
    expect(PlayerLens.dictate.dictationMode, isTrue);
    expect(PlayerLens.dictate.blurMode, isTrue);
  });
}
