import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Press = ({
  List<LogicalKeyboardKey> modifiers,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
});

_Press _press(
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical, [
  List<LogicalKeyboardKey> modifiers = const [],
]) => (modifiers: modifiers, logical: logical, physical: physical);

const _shift = LogicalKeyboardKey.shiftLeft;
const _ctrl = LogicalKeyboardKey.controlLeft;
const _meta = LogicalKeyboardKey.metaLeft;

/// What Linux / macOS deliver for each default chord: shifted punctuation
/// arrives as its own logical key (`?` for Shift+/, `<` for Shift+, …).
final Map<String, _Press> _linuxPresses = {
  'global.help': _press(
    LogicalKeyboardKey.question,
    PhysicalKeyboardKey.slash,
    [_shift],
  ),
  'global.search': _press(LogicalKeyboardKey.keyK, PhysicalKeyboardKey.keyK, [
    _ctrl,
  ]),
  'global.settings': _press(
    LogicalKeyboardKey.comma,
    PhysicalKeyboardKey.comma,
    [_ctrl],
  ),
  'global.craft': _press(LogicalKeyboardKey.keyC, PhysicalKeyboardKey.keyC),
  'player.togglePlay': _press(
    LogicalKeyboardKey.space,
    PhysicalKeyboardKey.space,
  ),
  'player.toggleExpand': _press(
    LogicalKeyboardKey.keyP,
    PhysicalKeyboardKey.keyP,
    [_ctrl, _shift],
  ),
  'player.toggleFullscreen': _press(
    LogicalKeyboardKey.f11,
    PhysicalKeyboardKey.f11,
  ),
  'player.prevLine': _press(LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA),
  'player.nextLine': _press(LogicalKeyboardKey.keyD, PhysicalKeyboardKey.keyD),
  'player.replayLine': _press(
    LogicalKeyboardKey.keyS,
    PhysicalKeyboardKey.keyS,
  ),
  'player.toggleEchoMode': _press(
    LogicalKeyboardKey.keyE,
    PhysicalKeyboardKey.keyE,
  ),
  'player.toggleBlurPractice': _press(
    LogicalKeyboardKey.keyH,
    PhysicalKeyboardKey.keyH,
  ),
  'player.toggleRecording': _press(
    LogicalKeyboardKey.keyR,
    PhysicalKeyboardKey.keyR,
  ),
  'player.toggleAssessment': _press(
    LogicalKeyboardKey.keyV,
    PhysicalKeyboardKey.keyV,
  ),
  'player.togglePitchContour': _press(
    LogicalKeyboardKey.keyP,
    PhysicalKeyboardKey.keyP,
  ),
  'player.playRecording': _press(
    LogicalKeyboardKey.keyG,
    PhysicalKeyboardKey.keyG,
  ),
  'player.slowDown': _press(
    LogicalKeyboardKey.less,
    PhysicalKeyboardKey.comma,
    [_shift],
  ),
  'player.speedUp': _press(
    LogicalKeyboardKey.greater,
    PhysicalKeyboardKey.period,
    [_shift],
  ),
  'player.expandEchoBackward': _press(
    LogicalKeyboardKey.bracketLeft,
    PhysicalKeyboardKey.bracketLeft,
  ),
  'player.expandEchoForward': _press(
    LogicalKeyboardKey.bracketRight,
    PhysicalKeyboardKey.bracketRight,
  ),
  'player.shrinkEchoBackward': _press(
    LogicalKeyboardKey.braceLeft,
    PhysicalKeyboardKey.bracketLeft,
    [_shift],
  ),
  'player.shrinkEchoForward': _press(
    LogicalKeyboardKey.braceRight,
    PhysicalKeyboardKey.bracketRight,
    [_shift],
  ),
  'library.search': _press(LogicalKeyboardKey.slash, PhysicalKeyboardKey.slash),
  'modal.close': _press(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape),
};

Future<KeyDownEvent> _capture(WidgetTester tester, _Press press) async {
  for (final m in press.modifiers) {
    await tester.sendKeyDownEvent(m);
  }
  return KeyDownEvent(
    physicalKey: press.physical,
    logicalKey: press.logical,
    timeStamp: Duration.zero,
  );
}

Future<void> _release(WidgetTester tester, _Press press) async {
  for (final m in press.modifiers.reversed) {
    await tester.sendKeyUpEvent(m);
  }
}

void main() {
  testWidgets('every default binding matches the event Linux delivers', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      _linuxPresses.keys.toSet(),
      hotkeyDefinitions.map((d) => d.id).toSet(),
    );
    for (final def in hotkeyDefinitions) {
      final press = _linuxPresses[def.id]!;
      final event = await _capture(tester, press);
      expect(
        hotkeyMatchesBinding(event, def.defaultKeys),
        isTrue,
        reason: '${def.id} (${def.defaultKeys})',
      );
      await _release(tester, press);
    }
  });

  testWidgets('capture serializes shifted punctuation to the stored form', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final cases = {
      'global.help': 'shift+slash',
      'player.shrinkEchoBackward': '{',
      'player.shrinkEchoForward': '}',
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      final press = _linuxPresses[key]!;
      final event = await _capture(tester, press);
      expect(serializeChordFromKeyEvent(event), value, reason: key);
      await _release(tester, press);
    }
  });

  testWidgets('macOS accepts Cmd for Ctrl bindings', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(const SizedBox.shrink());
      final press = _press(LogicalKeyboardKey.keyK, PhysicalKeyboardKey.keyK, [
        _meta,
      ]);
      final event = await _capture(tester, press);
      expect(hotkeyMatchesBinding(event, 'ctrl+k'), isTrue);
      expect(hotkeyMatchesBinding(event, 'k'), isFalse);
      await _release(tester, press);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Cmd does not satisfy Ctrl off macOS', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final press = _press(LogicalKeyboardKey.keyK, PhysicalKeyboardKey.keyK, [
      _meta,
    ]);
    final event = await _capture(tester, press);
    expect(hotkeyMatchesBinding(event, 'ctrl+k'), isFalse);
    await _release(tester, press);
  });
}
