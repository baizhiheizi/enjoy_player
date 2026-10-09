import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_top_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('echo shortcut chip renders only on desktop platforms', () {
    expect(echoModeShortcutVisible(), isDesktop);
  });
}
