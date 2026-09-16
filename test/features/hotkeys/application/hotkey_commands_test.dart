// Registry + dispatch-semantics tests for the hotkey command interface
// (issue #719): registration order is dispatch priority, a matched binding
// whose gate fails falls through to later commands (the old if-chain's
// semantics), and every `HotkeyDefinition` owns exactly one command.
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_commands.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HotkeysCtrl] answering from a fixed action id → binding map.
class _StaticHotkeysCtrl extends HotkeysCtrl {
  _StaticHotkeysCtrl(this.bindings);

  final Map<String, String> bindings;

  @override
  Future<Map<String, String>> build() async => bindings;

  @override
  String effectiveKeys(String actionId) => bindings[actionId] ?? '';
}

class _FakeCommand extends HotkeyCommand {
  _FakeCommand(this.actionId, {this.gate = true});

  @override
  final String actionId;

  /// When false, [execute] must not run and dispatch keeps scanning.
  final bool gate;

  int executed = 0;

  @override
  bool canExecute(HotkeyCtx ctx) => gate;

  @override
  void execute(HotkeyCtx ctx) => executed++;
}

KeyDownEvent _keyZ() => const KeyDownEvent(
  physicalKey: PhysicalKeyboardKey(0x1000000a),
  logicalKey: LogicalKeyboardKey.keyZ,
  timeStamp: Duration.zero,
);

void main() {
  // hotkeyMatchesBinding reads HardwareKeyboard.instance's pressed-modifier
  // state, so the services binding must exist even in these plain tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every HotkeyDefinition owns exactly one command', () {
    final commandIds = hotkeyCommands.map((c) => c.actionId).toList();
    expect(commandIds.toSet().length, commandIds.length,
        reason: 'duplicate actionId in the registry');
    expect(
      {for (final d in hotkeyDefinitions) d.id},
      unorderedEquals(commandIds),
      reason:
          'each definition needs exactly one HotkeyCommand (and each command '
          'a definition)',
    );
  });

  test('registry preserves the old if-chain priority order', () {
    expect(hotkeyCommands.map((c) => c.actionId).toList(), [
      'modal.close',
      'global.help',
      'global.settings',
      'global.craft',
      'global.search',
      'library.search',
      'player.toggleRecording',
      'player.playRecording',
      'player.togglePitchContour',
      'player.toggleAssessment',
      'player.togglePlay',
      'player.toggleExpand',
      'player.toggleFullscreen',
      'player.prevLine',
      'player.nextLine',
      'player.replayLine',
      'player.toggleEchoMode',
      'player.toggleBlurPractice',
      'player.slowDown',
      'player.speedUp',
      'player.expandEchoBackward',
      'player.expandEchoForward',
      'player.shrinkEchoBackward',
      'player.shrinkEchoForward',
    ]);
  });

  group('dispatchHotkey', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    HotkeyCtx ctx() =>
        HotkeyCtx(read: container.read, listenerContext: null);

    test('runs the first matching command and stops the scan', () {
      final first = _FakeCommand('a');
      final second = _FakeCommand('a');
      final ctrl = _StaticHotkeysCtrl({'a': 'z', 'b': 'z'});
      final handled = dispatchHotkey(
        event: _keyZ(),
        ctrl: ctrl,
        ctx: ctx(),
        commands: [first, second],
      );
      expect(handled, isTrue);
      expect(first.executed, 1);
      expect(second.executed, 0);
    });

    test('a matched-but-gated command falls through to later commands', () {
      final gated = _FakeCommand('a', gate: false);
      final fallback = _FakeCommand('b');
      final ctrl = _StaticHotkeysCtrl({'a': 'z', 'b': 'z'});
      final handled = dispatchHotkey(
        event: _keyZ(),
        ctrl: ctrl,
        ctx: ctx(),
        commands: [gated, fallback],
      );
      expect(handled, isTrue);
      expect(gated.executed, 0);
      expect(fallback.executed, 1);
    });

    test('returns false when nothing matches', () {
      final command = _FakeCommand('a');
      final handled = dispatchHotkey(
        event: _keyZ(),
        ctrl: _StaticHotkeysCtrl({'a': 'x'}),
        ctx: ctx(),
        commands: [command],
      );
      expect(handled, isFalse);
      expect(command.executed, 0);
    });

    test('skips commands whose binding is empty', () {
      final unbound = _FakeCommand('a');
      final handled = dispatchHotkey(
        event: _keyZ(),
        ctrl: _StaticHotkeysCtrl({'a': ''}),
        ctx: ctx(),
        commands: [unbound],
      );
      expect(handled, isFalse);
      expect(unbound.executed, 0);
    });

    test('execute is never called when canExecute is false', () {
      final gated = _FakeCommand('a', gate: false);
      dispatchHotkey(
        event: _keyZ(),
        ctrl: _StaticHotkeysCtrl({'a': 'z'}),
        ctx: ctx(),
        commands: [gated],
      );
      expect(gated.executed, 0);
    });
  });
}
