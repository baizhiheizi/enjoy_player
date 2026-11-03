import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_filter.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String everyEffective(String actionId) => switch (actionId) {
    'global.settings' => 'ctrl+shift+k',
    _ => '',
  };

  group('hotkeyScopeGroups', () {
    test('groups every definition under its scope in catalog order', () {
      final groups = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: '',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );

      expect(
        groups.map((group) => group.$1),
        HotkeyScope.values.where(
          (scope) => hotkeyDefinitions.any((d) => d.scope == scope),
        ),
      );
      expect(
        groups.map((group) => group.$2.length).reduce((a, b) => a + b),
        hotkeyDefinitions.length,
      );
    });

    test('skips scopes left empty by the query', () {
      final groups = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: 'settings',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );

      expect(groups, hasLength(1));
      expect(groups.single.$1, HotkeyScope.global);
      expect(groups.single.$2.map((d) => d.id), ['global.settings']);
    });

    test('matches against descriptions, scope labels, and bindings', () {
      final byBinding = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: 'ctrl+shift+k',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );
      final byDisplay = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: 'Ctrl+Shift+K',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );

      expect(byBinding.single.$2.map((d) => d.id), ['global.settings']);
      expect(byDisplay.single.$2.map((d) => d.id), ['global.settings']);

      final byId = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: 'global.settings',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );
      expect(byId.single.$2.map((d) => d.id), ['global.settings']);
    });

    test('returns an empty list when nothing matches', () {
      final groups = hotkeyScopeGroups(
        hotkeyDefinitions,
        query: 'zzzz-no-match',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );

      expect(groups, isEmpty);
    });

    test('respects a caller-provided subset such as customizable rows', () {
      final customizable = hotkeyDefinitions
          .where((d) => d.customizable)
          .toList();
      final groups = hotkeyScopeGroups(
        customizable,
        query: '',
        l10n: l10n,
        effectiveKeys: everyEffective,
      );

      expect(
        groups.map((group) => group.$2.length).reduce((a, b) => a + b),
        customizable.length,
      );
    });
  });
}
