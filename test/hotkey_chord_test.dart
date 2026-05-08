import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';

KeyDownEvent _keyDown(LogicalKeyboardKey key, String chars) {
  return KeyDownEvent(
    physicalKey: const PhysicalKeyboardKey(0),
    logicalKey: key,
    character: chars,
    timeStamp: Duration.zero,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseHotkeyString', () {
    test('parses ctrl+shift+p', () {
      final p = parseHotkeyString('ctrl+shift+p');
      expect(p.ctrl, true);
      expect(p.shift, true);
      expect(p.alt, false);
      expect(p.meta, false);
      expect(p.mainToken, 'p');
      expect(p.canonical, 'ctrl+shift+p');
    });

    test('parses shift+comma', () {
      final p = parseHotkeyString('shift+comma');
      expect(p.shift, true);
      expect(p.mainToken, 'comma');
    });

    test('parses shift+slash', () {
      final p = parseHotkeyString('shift+slash');
      expect(p.shift, true);
      expect(p.mainToken, 'slash');
    });

    test('parses brace aliases', () {
      final open = parseHotkeyString('{');
      expect(open.shift, true);
      expect(open.mainToken, '[');

      final close = parseHotkeyString('}');
      expect(close.shift, true);
      expect(close.mainToken, ']');
    });

    test('throws on empty', () {
      expect(() => parseHotkeyString(''), throwsFormatException);
      expect(() => parseHotkeyString('   '), throwsFormatException);
    });
  });

  group('hotkeyMatchesParsed bare letter', () {
    test('matches k when no modifiers', () {
      final p = parseHotkeyString('k');
      final ev = _keyDown(LogicalKeyboardKey.keyK, 'k');
      expect(hotkeyMatchesParsed(ev, p), isTrue);
    });

    test('matches space', () {
      final p = parseHotkeyString('space');
      final ev = _keyDown(LogicalKeyboardKey.space, ' ');
      expect(hotkeyMatchesParsed(ev, p), isTrue);
    });

    test('matches slash', () {
      final p = parseHotkeyString('/');
      final ev = _keyDown(LogicalKeyboardKey.slash, '/');
      expect(hotkeyMatchesParsed(ev, p), isTrue);
    });

    test('matches bracket keys', () {
      expect(
        hotkeyMatchesParsed(
          _keyDown(LogicalKeyboardKey.bracketLeft, '['),
          parseHotkeyString('['),
        ),
        isTrue,
      );
      expect(
        hotkeyMatchesParsed(
          _keyDown(LogicalKeyboardKey.bracketRight, ']'),
          parseHotkeyString(']'),
        ),
        isTrue,
      );
    });
  });

  group('conflict detection', () {
    test('same chord conflicts', () {
      expect(hotkeyBindingsConflict('ctrl+k', 'ctrl+k'), isTrue);
    });

    test('modifier order canonicalized', () {
      expect(
        parseHotkeyString('shift+ctrl+p').canonical,
        parseHotkeyString('ctrl+shift+p').canonical,
      );
    });
  });
}
