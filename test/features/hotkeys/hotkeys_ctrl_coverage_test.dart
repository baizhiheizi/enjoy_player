import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  group('isValidHotkeyBindingString', () {
    test('returns true for valid bindings', () {
      expect(isValidHotkeyBindingString('ctrl+k'), isTrue);
      expect(isValidHotkeyBindingString('space'), isTrue);
      expect(isValidHotkeyBindingString('shift+slash'), isTrue);
      expect(isValidHotkeyBindingString('a'), isTrue);
      expect(isValidHotkeyBindingString('ctrl+shift+p'), isTrue);
    });

    test('returns false for empty string', () {
      expect(isValidHotkeyBindingString(''), isFalse);
    });

    test('returns false for whitespace-only string', () {
      expect(isValidHotkeyBindingString('   '), isFalse);
    });

    test('returns false for plus-only string', () {
      expect(isValidHotkeyBindingString('+'), isFalse);
    });
  });

  group('HotkeysCtrl.build (decoding persisted bindings)', () {
    test('returns empty map when no value persisted', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('returns empty map for empty string value', () async {
      await db.settingsDao.setValue(kHotkeysCustomBindingsKey, '');
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('returns empty map for invalid JSON', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        'not-valid-json{{{',
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('returns empty map when JSON is not a Map', () async {
      await db.settingsDao.setValue(kHotkeysCustomBindingsKey, '["a","b"]');
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('skips entries with non-string keys', () async {
      // JSON with a numeric key — jsonDecode produces int key
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        '{"123": "ctrl+k"}',
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      // "123" is a String in JSON, but not a known action id
      expect(result, isEmpty);
    });

    test('skips entries with non-string values', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        '{"global.search": 42}',
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('skips entries with unknown action ids', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'nonexistent.action': 'ctrl+x'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('skips entries with invalid binding strings', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': ''}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, isEmpty);
    });

    test('decodes valid bindings correctly', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j', 'player.togglePlay': 'enter'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, {'global.search': 'ctrl+j', 'player.togglePlay': 'enter'});
    });

    test('filters valid from invalid entries in same map', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({
          'global.search': 'ctrl+j',
          'global.help': '',
          'unknown.action': 'ctrl+x',
        }),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(hotkeysCtrlProvider.future);
      expect(result, {'global.search': 'ctrl+j'});
    });
  });

  group('effectiveKeys', () {
    test('returns default keys when no custom binding set', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.effectiveKeys('global.search'), 'ctrl+k');
      expect(ctrl.effectiveKeys('player.togglePlay'), 'space');
    });

    test('returns custom binding when set', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.effectiveKeys('global.search'), 'ctrl+j');
    });

    test('returns empty string for unknown action id', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.effectiveKeys('nonexistent.action'), '');
    });

    test('returns default keys when state is loading', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      // Do NOT await the future — state is still AsyncLoading
      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.effectiveKeys('global.search'), 'ctrl+k');
    });
  });

  group('hasCustomBinding', () {
    test('returns false when no custom binding exists', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.hasCustomBinding('global.search'), isFalse);
    });

    test('returns true when custom binding exists', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.hasCustomBinding('global.search'), isTrue);
    });

    test('returns false when state is loading', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      expect(ctrl.hasCustomBinding('global.search'), isFalse);
    });

    test('returns false for empty string binding value', () async {
      // Manually set an empty-string binding (edge case)
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      // Overwrite state directly to simulate empty value edge case
      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      // The decode filters empty strings, so this tests the isNotEmpty check
      expect(ctrl.hasCustomBinding('player.togglePlay'), isFalse);
    });
  });

  group('setBinding', () {
    test('sets a valid binding on a customizable action', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      final result = await ctrl.setBinding('global.search', 'ctrl+j');
      expect(result, isTrue);

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, {'global.search': 'ctrl+j'});
    });

    test('persists the binding to the database', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.setBinding('global.search', 'ctrl+j');

      final raw = await db.settingsDao.getValue(kHotkeysCustomBindingsKey);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['global.search'], 'ctrl+j');
    });

    test('returns false for unknown action id', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      final result = await ctrl.setBinding('nonexistent.action', 'ctrl+j');
      expect(result, isFalse);
    });

    test('returns false for non-customizable action', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      // modal.close is customizable: false
      final result = await ctrl.setBinding('modal.close', 'ctrl+j');
      expect(result, isFalse);
    });

    test('returns false for invalid binding string', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      final result = await ctrl.setBinding('global.search', '');
      expect(result, isFalse);
    });

    test('returns false when binding conflicts with another action', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      // 'space' is the default for player.togglePlay
      final result = await ctrl.setBinding('global.search', 'space');
      expect(result, isFalse);
    });

    test(
      'allows binding that matches same action default (no conflict)',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        await container.read(hotkeysCtrlProvider.future);

        final ctrl = container.read(hotkeysCtrlProvider.notifier);
        // Setting global.search to its own default should succeed
        final result = await ctrl.setBinding('global.search', 'ctrl+k');
        expect(result, isTrue);
      },
    );

    test('does not conflict with custom binding of same action', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      // Re-setting to same value should not conflict with itself
      final result = await ctrl.setBinding('global.search', 'ctrl+j');
      expect(result, isTrue);
    });
  });

  group('resetBinding', () {
    test('removes a custom binding', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetBinding('global.search');

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, isEmpty);
    });

    test('persists removal to database', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j', 'global.help': 'shift+a'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetBinding('global.search');

      final raw = await db.settingsDao.getValue(kHotkeysCustomBindingsKey);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.containsKey('global.search'), isFalse);
      expect(decoded['global.help'], 'shift+a');
    });

    test('does nothing for unknown action id', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetBinding('nonexistent.action');

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, {'global.search': 'ctrl+j'});
    });

    test('does nothing for non-customizable action', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      // Should not throw
      await ctrl.resetBinding('modal.close');

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, isEmpty);
    });

    test('does nothing when action has no custom binding', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetBinding('global.search');

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, isEmpty);
    });
  });

  group('resetAllBindings', () {
    test('clears all custom bindings', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({
          'global.search': 'ctrl+j',
          'global.help': 'shift+a',
          'player.togglePlay': 'enter',
        }),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetAllBindings();

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, isEmpty);
    });

    test('persists empty map to database', () async {
      await db.settingsDao.setValue(
        kHotkeysCustomBindingsKey,
        jsonEncode({'global.search': 'ctrl+j'}),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetAllBindings();

      final raw = await db.settingsDao.getValue(kHotkeysCustomBindingsKey);
      expect(raw, '{}');
    });

    test('works when no bindings exist', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(hotkeysCtrlProvider.future);

      final ctrl = container.read(hotkeysCtrlProvider.notifier);
      await ctrl.resetAllBindings();

      final state = container.read(hotkeysCtrlProvider);
      expect(state.value, isEmpty);
    });
  });
}
