import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('global.craft hotkey definition', () {
    test('is registered as a global, customizable "c" shortcut', () {
      final craft = hotkeyDefinitionMap['global.craft'];
      expect(craft, isNotNull);
      expect(craft!.defaultKeys, 'c');
      expect(craft.descriptionKey, 'craft');
      expect(craft.scope, HotkeyScope.global);
      expect(craft.customizable, isTrue);
    });

    test('appears in the global scope list', () {
      final globalHotkeys = hotkeysByScope(HotkeyScope.global);
      expect(globalHotkeys.map((d) => d.id), contains('global.craft'));
    });
  });
}
