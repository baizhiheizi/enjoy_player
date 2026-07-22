import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

KeyDownEvent _keyDown(LogicalKeyboardKey key, [String? character]) {
  return KeyDownEvent(
    physicalKey: const PhysicalKeyboardKey(0),
    logicalKey: key,
    character: character,
    timeStamp: Duration.zero,
  );
}

KeyUpEvent _keyUp(LogicalKeyboardKey key, [PhysicalKeyboardKey? physical]) {
  return KeyUpEvent(
    physicalKey: physical ?? const PhysicalKeyboardKey(0),
    logicalKey: key,
    timeStamp: Duration.zero,
  );
}

PhysicalKeyboardKey _physicalForModifier(LogicalKeyboardKey logical) {
  if (logical == LogicalKeyboardKey.controlLeft) {
    return PhysicalKeyboardKey.controlLeft;
  }
  if (logical == LogicalKeyboardKey.controlRight) {
    return PhysicalKeyboardKey.controlRight;
  }
  if (logical == LogicalKeyboardKey.shiftLeft) {
    return PhysicalKeyboardKey.shiftLeft;
  }
  if (logical == LogicalKeyboardKey.shiftRight) {
    return PhysicalKeyboardKey.shiftRight;
  }
  if (logical == LogicalKeyboardKey.altLeft) {
    return PhysicalKeyboardKey.altLeft;
  }
  if (logical == LogicalKeyboardKey.altRight) {
    return PhysicalKeyboardKey.altRight;
  }
  if (logical == LogicalKeyboardKey.metaLeft) {
    return PhysicalKeyboardKey.metaLeft;
  }
  return PhysicalKeyboardKey.metaRight;
}

void _pressModifier(LogicalKeyboardKey key) {
  final physical = _physicalForModifier(key);
  HardwareKeyboard.instance.handleKeyEvent(
    KeyDownEvent(
      physicalKey: physical,
      logicalKey: key,
      timeStamp: Duration.zero,
    ),
  );
}

void _releaseModifier(LogicalKeyboardKey key) {
  final physical = _physicalForModifier(key);
  HardwareKeyboard.instance.handleKeyEvent(_keyUp(key, physical));
}

void _releaseAllModifiers() {
  const modifiers = [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  ];
  for (final key in modifiers) {
    _releaseModifier(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(_releaseAllModifiers);

  group('parseHotkeyString', () {
    test('parses simple letter', () {
      final p = parseHotkeyString('a');
      expect(p.ctrl, isFalse);
      expect(p.shift, isFalse);
      expect(p.alt, isFalse);
      expect(p.meta, isFalse);
      expect(p.mainToken, 'a');
    });

    test('lowercases uppercase letter', () {
      final p = parseHotkeyString('Z');
      expect(p.mainToken, 'z');
    });

    test('parses ctrl modifier', () {
      final p = parseHotkeyString('ctrl+x');
      expect(p.ctrl, isTrue);
      expect(p.mainToken, 'x');
    });

    test('parses control alias', () {
      final p = parseHotkeyString('control+x');
      expect(p.ctrl, isTrue);
      expect(p.mainToken, 'x');
    });

    test('parses shift modifier', () {
      final p = parseHotkeyString('shift+a');
      expect(p.shift, isTrue);
      expect(p.mainToken, 'a');
    });

    test('parses alt modifier', () {
      final p = parseHotkeyString('alt+f');
      expect(p.alt, isTrue);
      expect(p.mainToken, 'f');
    });

    test('parses meta modifier', () {
      final p = parseHotkeyString('meta+s');
      expect(p.meta, isTrue);
      expect(p.mainToken, 's');
    });

    test('parses cmd alias as meta', () {
      final p = parseHotkeyString('cmd+s');
      expect(p.meta, isTrue);
      expect(p.mainToken, 's');
    });

    test('parses multiple modifiers', () {
      final p = parseHotkeyString('ctrl+alt+shift+k');
      expect(p.ctrl, isTrue);
      expect(p.alt, isTrue);
      expect(p.shift, isTrue);
      expect(p.meta, isFalse);
      expect(p.mainToken, 'k');
    });

    test('parses all four modifiers', () {
      final p = parseHotkeyString('ctrl+shift+alt+meta+x');
      expect(p.ctrl, isTrue);
      expect(p.shift, isTrue);
      expect(p.alt, isTrue);
      expect(p.meta, isTrue);
      expect(p.mainToken, 'x');
    });

    test('parses brace open as shift+[', () {
      final p = parseHotkeyString('{');
      expect(p.shift, isTrue);
      expect(p.mainToken, '[');
    });

    test('parses brace close as shift+]', () {
      final p = parseHotkeyString('}');
      expect(p.shift, isTrue);
      expect(p.mainToken, ']');
    });

    test('parses named keys', () {
      expect(parseHotkeyString('space').mainToken, 'space');
      expect(parseHotkeyString('escape').mainToken, 'escape');
      expect(parseHotkeyString('enter').mainToken, 'enter');
      expect(parseHotkeyString('tab').mainToken, 'tab');
      expect(parseHotkeyString('backspace').mainToken, 'backspace');
      expect(parseHotkeyString('delete').mainToken, 'delete');
      expect(parseHotkeyString('comma').mainToken, 'comma');
      expect(parseHotkeyString('period').mainToken, 'period');
      expect(parseHotkeyString('slash').mainToken, 'slash');
      expect(parseHotkeyString('backslash').mainToken, 'backslash');
      expect(parseHotkeyString('minus').mainToken, 'minus');
      expect(parseHotkeyString('equal').mainToken, 'equal');
      expect(parseHotkeyString('semicolon').mainToken, 'semicolon');
      expect(parseHotkeyString('quote').mainToken, 'quote');
      expect(parseHotkeyString('apostrophe').mainToken, 'apostrophe');
      expect(parseHotkeyString('bracketleft').mainToken, 'bracketleft');
      expect(parseHotkeyString('bracketright').mainToken, 'bracketright');
      expect(parseHotkeyString('arrowleft').mainToken, 'arrowleft');
      expect(parseHotkeyString('arrowright').mainToken, 'arrowright');
      expect(parseHotkeyString('arrowup').mainToken, 'arrowup');
      expect(parseHotkeyString('arrowdown').mainToken, 'arrowdown');
    });

    test('lowercases multi-char main token', () {
      final p = parseHotkeyString('SPACE');
      expect(p.mainToken, 'space');
    });

    test('preserves single punctuation char', () {
      expect(parseHotkeyString('/').mainToken, '/');
      expect(parseHotkeyString(',').mainToken, ',');
      expect(parseHotkeyString('.').mainToken, '.');
      expect(parseHotkeyString(';').mainToken, ';');
      expect(parseHotkeyString('-').mainToken, '-');
      expect(parseHotkeyString('=').mainToken, '=');
      expect(parseHotkeyString('`').mainToken, '`');
    });

    test('stops consuming modifiers at non-modifier token', () {
      final p = parseHotkeyString('a+ctrl+b');
      expect(p.ctrl, isFalse);
      expect(p.mainToken, 'a+ctrl+b');
    });

    test('trims whitespace around binding', () {
      final p = parseHotkeyString('  ctrl+a  ');
      expect(p.ctrl, isTrue);
      expect(p.mainToken, 'a');
    });

    test('throws FormatException on empty string', () {
      expect(() => parseHotkeyString(''), throwsFormatException);
    });

    test('throws FormatException on whitespace-only string', () {
      expect(() => parseHotkeyString('   '), throwsFormatException);
    });

    test('throws FormatException on plus-only string', () {
      expect(() => parseHotkeyString('+'), throwsFormatException);
    });

    test(
      'treats trailing modifier as main token when no non-modifier follows',
      () {
        final p = parseHotkeyString('ctrl+shift+');
        expect(p.ctrl, isTrue);
        expect(p.mainToken, 'shift');
      },
    );

    test('parses f-key tokens', () {
      expect(parseHotkeyString('f1').mainToken, 'f1');
      expect(parseHotkeyString('F12').mainToken, 'f12');
      expect(parseHotkeyString('ctrl+f5').mainToken, 'f5');
    });
  });

  group('ParsedHotkey.canonical', () {
    test('returns mainToken alone when no modifiers', () {
      final p = parseHotkeyString('space');
      expect(p.canonical, 'space');
    });

    test('sorts modifiers alphabetically', () {
      final p = parseHotkeyString('shift+ctrl+alt+meta+x');
      expect(p.canonical, 'alt+ctrl+meta+shift+x');
    });

    test('canonicalizes different modifier orders to same string', () {
      final a = parseHotkeyString('ctrl+shift+p');
      final b = parseHotkeyString('shift+ctrl+p');
      expect(a.canonical, b.canonical);
    });

    test('single modifier', () {
      expect(parseHotkeyString('ctrl+k').canonical, 'ctrl+k');
      expect(parseHotkeyString('alt+f').canonical, 'alt+f');
      expect(parseHotkeyString('meta+s').canonical, 'meta+s');
      expect(parseHotkeyString('shift+a').canonical, 'shift+a');
    });
  });

  group('hotkeyMatchesParsed', () {
    test('returns false for KeyUpEvent', () {
      final p = parseHotkeyString('a');
      final event = _keyUp(LogicalKeyboardKey.keyA);
      expect(hotkeyMatchesParsed(event, p), isFalse);
    });

    test(
      'returns false when modifier mismatch (ctrl expected, not pressed)',
      () {
        final p = parseHotkeyString('ctrl+a');
        final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
        expect(hotkeyMatchesParsed(event, p), isFalse);
      },
    );

    test('returns false when extra modifier pressed', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      final p = parseHotkeyString('a');
      final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
      expect(hotkeyMatchesParsed(event, p), isFalse);
    });

    test('matches ctrl+letter when ctrl held', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      final p = parseHotkeyString('ctrl+c');
      final event = _keyDown(LogicalKeyboardKey.keyC, 'c');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('matches shift+letter when shift held', () {
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      final p = parseHotkeyString('shift+a');
      final event = _keyDown(LogicalKeyboardKey.keyA, 'A');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('matches alt+letter when alt held', () {
      _pressModifier(LogicalKeyboardKey.altLeft);
      final p = parseHotkeyString('alt+f');
      final event = _keyDown(LogicalKeyboardKey.keyF, 'f');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('matches meta+letter when meta held', () {
      _pressModifier(LogicalKeyboardKey.metaLeft);
      final p = parseHotkeyString('meta+v');
      final event = _keyDown(LogicalKeyboardKey.keyV, 'v');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('bare letter matches without modifiers', () {
      final p = parseHotkeyString('k');
      final event = _keyDown(LogicalKeyboardKey.keyK, 'k');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('matches all letter keys a-z', () {
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      final logicalKeys = [
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyJ,
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyN,
        LogicalKeyboardKey.keyO,
        LogicalKeyboardKey.keyP,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.keyY,
        LogicalKeyboardKey.keyZ,
      ];
      for (var i = 0; i < 26; i++) {
        final p = parseHotkeyString(letters[i]);
        final event = _keyDown(logicalKeys[i], letters[i]);
        expect(
          hotkeyMatchesParsed(event, p),
          isTrue,
          reason: 'letter ${letters[i]} should match',
        );
      }
    });

    test('matches space', () {
      final p = parseHotkeyString('space');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.space, ' '), p),
        isTrue,
      );
    });

    test('matches escape', () {
      final p = parseHotkeyString('escape');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.escape), p),
        isTrue,
      );
    });

    test('matches enter', () {
      final p = parseHotkeyString('enter');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.enter), p),
        isTrue,
      );
    });

    test('matches return alias for enter', () {
      final p = parseHotkeyString('return');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.enter), p),
        isTrue,
      );
    });

    test('matches tab', () {
      final p = parseHotkeyString('tab');
      expect(hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.tab), p), isTrue);
    });

    test('matches backspace', () {
      final p = parseHotkeyString('backspace');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.backspace), p),
        isTrue,
      );
    });

    test('matches delete', () {
      final p = parseHotkeyString('delete');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.delete), p),
        isTrue,
      );
    });

    test('matches comma', () {
      final p = parseHotkeyString('comma');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.comma, ','), p),
        isTrue,
      );
    });

    test('matches period', () {
      final p = parseHotkeyString('period');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.period, '.'), p),
        isTrue,
      );
    });

    test('matches slash named token', () {
      final p = parseHotkeyString('slash');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.slash, '/'), p),
        isTrue,
      );
    });

    test('matches backslash', () {
      final p = parseHotkeyString('backslash');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.backslash, '\\'), p),
        isTrue,
      );
    });

    test('matches minus', () {
      final p = parseHotkeyString('minus');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.minus, '-'), p),
        isTrue,
      );
    });

    test('matches equal', () {
      final p = parseHotkeyString('equal');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.equal, '='), p),
        isTrue,
      );
    });

    test('matches semicolon', () {
      final p = parseHotkeyString('semicolon');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.semicolon, ';'), p),
        isTrue,
      );
    });

    test('matches quote', () {
      final p = parseHotkeyString('quote');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.quote, "'"), p),
        isTrue,
      );
    });

    test('matches apostrophe alias for quote', () {
      final p = parseHotkeyString('apostrophe');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.quote, "'"), p),
        isTrue,
      );
    });

    test('matches bracketleft named token', () {
      final p = parseHotkeyString('bracketleft');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.bracketLeft, '['), p),
        isTrue,
      );
    });

    test('matches bracketright named token', () {
      final p = parseHotkeyString('bracketright');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.bracketRight, ']'), p),
        isTrue,
      );
    });

    test('matches arrowleft', () {
      final p = parseHotkeyString('arrowleft');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.arrowLeft), p),
        isTrue,
      );
    });

    test('matches arrowright', () {
      final p = parseHotkeyString('arrowright');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.arrowRight), p),
        isTrue,
      );
    });

    test('matches arrowup', () {
      final p = parseHotkeyString('arrowup');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.arrowUp), p),
        isTrue,
      );
    });

    test('matches arrowdown', () {
      final p = parseHotkeyString('arrowdown');
      expect(
        hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.arrowDown), p),
        isTrue,
      );
    });

    group('punctuation single-char matching', () {
      test('matches / char', () {
        final p = parseHotkeyString('/');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.slash, '/'), p),
          isTrue,
        );
      });

      test('matches ` char', () {
        final p = parseHotkeyString('`');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.backquote, '`'), p),
          isTrue,
        );
      });

      test('matches [ char', () {
        final p = parseHotkeyString('[');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.bracketLeft, '['), p),
          isTrue,
        );
      });

      test('matches ] char', () {
        final p = parseHotkeyString(']');
        expect(
          hotkeyMatchesParsed(
            _keyDown(LogicalKeyboardKey.bracketRight, ']'),
            p,
          ),
          isTrue,
        );
      });

      test('matches , char', () {
        final p = parseHotkeyString(',');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.comma, ','), p),
          isTrue,
        );
      });

      test('matches . char', () {
        final p = parseHotkeyString('.');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.period, '.'), p),
          isTrue,
        );
      });

      test('matches ; char', () {
        final p = parseHotkeyString(';');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.semicolon, ';'), p),
          isTrue,
        );
      });

      test("matches ' char", () {
        final p = parseHotkeyString("'");
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.quote, "'"), p),
          isTrue,
        );
      });

      test('matches - char', () {
        final p = parseHotkeyString('-');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.minus, '-'), p),
          isTrue,
        );
      });

      test('matches = char', () {
        final p = parseHotkeyString('=');
        expect(
          hotkeyMatchesParsed(_keyDown(LogicalKeyboardKey.equal, '='), p),
          isTrue,
        );
      });
    });

    group('f-key matching', () {
      test('matches f1 through f12', () {
        final fKeys = [
          LogicalKeyboardKey.f1,
          LogicalKeyboardKey.f2,
          LogicalKeyboardKey.f3,
          LogicalKeyboardKey.f4,
          LogicalKeyboardKey.f5,
          LogicalKeyboardKey.f6,
          LogicalKeyboardKey.f7,
          LogicalKeyboardKey.f8,
          LogicalKeyboardKey.f9,
          LogicalKeyboardKey.f10,
          LogicalKeyboardKey.f11,
          LogicalKeyboardKey.f12,
        ];
        for (var i = 0; i < 12; i++) {
          final p = parseHotkeyString('f${i + 1}');
          final event = _keyDown(fKeys[i]);
          expect(
            hotkeyMatchesParsed(event, p),
            isTrue,
            reason: 'f${i + 1} should match',
          );
        }
      });

      test('does not match f13 or higher', () {
        final p = parseHotkeyString('f13');
        final event = _keyDown(const LogicalKeyboardKey(0x00100000800 + 13));
        expect(hotkeyMatchesParsed(event, p), isFalse);
      });

      test('does not match f0', () {
        final p = parseHotkeyString('f0');
        final event = _keyDown(LogicalKeyboardKey.f1);
        expect(hotkeyMatchesParsed(event, p), isFalse);
      });

      test('does not match f25', () {
        final p = parseHotkeyString('f25');
        final event = _keyDown(LogicalKeyboardKey.f12);
        expect(hotkeyMatchesParsed(event, p), isFalse);
      });
    });

    test('returns false for unknown multi-char token', () {
      final p = parseHotkeyString('unknownkey');
      final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
      expect(hotkeyMatchesParsed(event, p), isFalse);
    });

    test('returns false when main key does not match', () {
      final p = parseHotkeyString('a');
      final event = _keyDown(LogicalKeyboardKey.keyB, 'b');
      expect(hotkeyMatchesParsed(event, p), isFalse);
    });

    test('matches ctrl+shift combo', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      final p = parseHotkeyString('ctrl+shift+p');
      final event = _keyDown(LogicalKeyboardKey.keyP, 'P');
      expect(hotkeyMatchesParsed(event, p), isTrue);
    });

    test('returns false when wrong key pressed with correct modifiers', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      final p = parseHotkeyString('ctrl+a');
      final event = _keyDown(LogicalKeyboardKey.keyB, 'b');
      expect(hotkeyMatchesParsed(event, p), isFalse);
    });
  });

  group('hotkeyMatchesBinding', () {
    test('returns true for matching binding', () {
      final event = _keyDown(LogicalKeyboardKey.space, ' ');
      expect(hotkeyMatchesBinding(event, 'space'), isTrue);
    });

    test('returns false for non-matching binding', () {
      final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
      expect(hotkeyMatchesBinding(event, 'space'), isFalse);
    });

    test('returns false for invalid binding string', () {
      final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
      expect(hotkeyMatchesBinding(event, ''), isFalse);
      expect(hotkeyMatchesBinding(event, '   '), isFalse);
    });

    test('returns false for KeyUpEvent', () {
      final event = _keyUp(LogicalKeyboardKey.keyA);
      expect(hotkeyMatchesBinding(event, 'a'), isFalse);
    });

    test('matches binding with modifiers', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      final event = _keyDown(LogicalKeyboardKey.keyS, 's');
      expect(hotkeyMatchesBinding(event, 'ctrl+s'), isTrue);
    });
  });

  group('hotkeyBindingsConflict', () {
    test('identical bindings conflict', () {
      expect(hotkeyBindingsConflict('ctrl+k', 'ctrl+k'), isTrue);
    });

    test('different bindings do not conflict', () {
      expect(hotkeyBindingsConflict('ctrl+k', 'ctrl+j'), isFalse);
    });

    test('different modifiers do not conflict', () {
      expect(hotkeyBindingsConflict('ctrl+a', 'shift+a'), isFalse);
    });

    test('modifier order does not affect conflict', () {
      expect(hotkeyBindingsConflict('shift+ctrl+p', 'ctrl+shift+p'), isTrue);
    });

    test('control and ctrl aliases conflict', () {
      expect(hotkeyBindingsConflict('control+a', 'ctrl+a'), isTrue);
    });

    test('cmd and meta aliases conflict', () {
      expect(hotkeyBindingsConflict('cmd+s', 'meta+s'), isTrue);
    });

    test('brace aliases conflict with shift+bracket', () {
      expect(hotkeyBindingsConflict('{', 'shift+['), isTrue);
      expect(hotkeyBindingsConflict('}', 'shift+]'), isTrue);
    });

    test('returns false when candidate is invalid', () {
      expect(hotkeyBindingsConflict('', 'ctrl+a'), isFalse);
    });

    test('returns false when existing is invalid', () {
      expect(hotkeyBindingsConflict('ctrl+a', ''), isFalse);
    });

    test('returns false when both are invalid', () {
      expect(hotkeyBindingsConflict('', ''), isFalse);
    });
  });

  group('serializeChordFromKeyEvent', () {
    test('serializes letter key without modifiers', () {
      final event = _keyDown(LogicalKeyboardKey.keyA, 'a');
      expect(serializeChordFromKeyEvent(event), 'a');
    });

    test('serializes all letter keys', () {
      final logicalKeys = [
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyJ,
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyN,
        LogicalKeyboardKey.keyO,
        LogicalKeyboardKey.keyP,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.keyY,
        LogicalKeyboardKey.keyZ,
      ];
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      for (var i = 0; i < 26; i++) {
        final event = _keyDown(logicalKeys[i], letters[i]);
        expect(
          serializeChordFromKeyEvent(event),
          letters[i],
          reason: 'key ${letters[i]}',
        );
      }
    });

    test('serializes space', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.space, ' ')),
        'space',
      );
    });

    test('serializes escape', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.escape)),
        'escape',
      );
    });

    test('serializes enter', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.enter)),
        'enter',
      );
    });

    test('serializes tab', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.tab)),
        'tab',
      );
    });

    test('serializes backspace', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.backspace)),
        'backspace',
      );
    });

    test('serializes delete', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.delete)),
        'delete',
      );
    });

    test('serializes comma', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.comma, ',')),
        'comma',
      );
    });

    test('serializes period', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.period, '.')),
        'period',
      );
    });

    test('serializes slash without shift as /', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.slash, '/')),
        '/',
      );
    });

    test('serializes slash with shift as slash', () {
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.slash, '?')),
        'shift+slash',
      );
    });

    test('serializes bracketLeft as [', () {
      expect(
        serializeChordFromKeyEvent(
          _keyDown(LogicalKeyboardKey.bracketLeft, '['),
        ),
        '[',
      );
    });

    test('serializes bracketRight as ]', () {
      expect(
        serializeChordFromKeyEvent(
          _keyDown(LogicalKeyboardKey.bracketRight, ']'),
        ),
        ']',
      );
    });

    test('serializes shift+bracketLeft as {', () {
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      expect(
        serializeChordFromKeyEvent(
          _keyDown(LogicalKeyboardKey.bracketLeft, '{'),
        ),
        '{',
      );
    });

    test('serializes shift+bracketRight as }', () {
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      expect(
        serializeChordFromKeyEvent(
          _keyDown(LogicalKeyboardKey.bracketRight, '}'),
        ),
        '}',
      );
    });

    test('does not serialize ctrl+shift+bracketLeft as {', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      final result = serializeChordFromKeyEvent(
        _keyDown(LogicalKeyboardKey.bracketLeft),
      );
      expect(result, 'ctrl+shift+[');
    });

    test('serializes backslash', () {
      expect(
        serializeChordFromKeyEvent(
          _keyDown(LogicalKeyboardKey.backslash, '\\'),
        ),
        'backslash',
      );
    });

    test('serializes minus', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.minus, '-')),
        'minus',
      );
    });

    test('serializes equal', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.equal, '=')),
        'equal',
      );
    });

    test('serializes arrowLeft', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft)),
        'arrowleft',
      );
    });

    test('serializes arrowRight', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.arrowRight)),
        'arrowright',
      );
    });

    test('serializes arrowUp', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.arrowUp)),
        'arrowup',
      );
    });

    test('serializes arrowDown', () {
      expect(
        serializeChordFromKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown)),
        'arrowdown',
      );
    });

    test('serializes with ctrl modifier', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      final event = _keyDown(LogicalKeyboardKey.keyS, 's');
      expect(serializeChordFromKeyEvent(event), 'ctrl+s');
    });

    test('serializes with shift modifier', () {
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      final event = _keyDown(LogicalKeyboardKey.keyA, 'A');
      expect(serializeChordFromKeyEvent(event), 'shift+a');
    });

    test('serializes with alt modifier', () {
      _pressModifier(LogicalKeyboardKey.altLeft);
      final event = _keyDown(LogicalKeyboardKey.keyF, 'f');
      expect(serializeChordFromKeyEvent(event), 'alt+f');
    });

    test('serializes with meta modifier', () {
      _pressModifier(LogicalKeyboardKey.metaLeft);
      final event = _keyDown(LogicalKeyboardKey.keyV, 'v');
      expect(serializeChordFromKeyEvent(event), 'meta+v');
    });

    test('serializes with multiple modifiers in order ctrl+shift+alt+meta', () {
      _pressModifier(LogicalKeyboardKey.controlLeft);
      _pressModifier(LogicalKeyboardKey.shiftLeft);
      _pressModifier(LogicalKeyboardKey.altLeft);
      _pressModifier(LogicalKeyboardKey.metaLeft);
      final event = _keyDown(LogicalKeyboardKey.keyX, 'x');
      expect(serializeChordFromKeyEvent(event), 'ctrl+shift+alt+meta+x');
    });

    test('returns null for unrecognized key', () {
      final event = _keyDown(LogicalKeyboardKey.capsLock);
      expect(serializeChordFromKeyEvent(event), isNull);
    });

    test('returns null for numLock', () {
      final event = _keyDown(LogicalKeyboardKey.numLock);
      expect(serializeChordFromKeyEvent(event), isNull);
    });

    test('serializes semicolon key as null (not in serializer list)', () {
      final event = _keyDown(LogicalKeyboardKey.semicolon, ';');
      final result = serializeChordFromKeyEvent(event);
      expect(result, isNull);
    });

    test('serializes quote key as null (not in serializer list)', () {
      final event = _keyDown(LogicalKeyboardKey.quote, "'");
      final result = serializeChordFromKeyEvent(event);
      expect(result, isNull);
    });

    test('serializes backquote key as null (not in serializer list)', () {
      final event = _keyDown(LogicalKeyboardKey.backquote, '`');
      final result = serializeChordFromKeyEvent(event);
      expect(result, isNull);
    });
  });
}
