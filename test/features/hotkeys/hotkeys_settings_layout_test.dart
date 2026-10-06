import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _FakeHotkeysCtrl extends HotkeysCtrl {
  _FakeHotkeysCtrl(this._bindings);

  final Map<String, String> _bindings;

  @override
  Future<Map<String, String>> build() async => Map.of(_bindings);

  @override
  Future<void> resetBinding(String actionId) async {
    state = AsyncData(Map.of(_bindings)..remove(actionId));
  }
}

Override _override(Map<String, String> bindings) {
  return hotkeysCtrlProvider.overrideWith(() => _FakeHotkeysCtrl(bindings));
}

const _surface = Size(1000, 1600);

Widget _app({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HotkeysSettingsSection()),
    ),
  );
}

List<HotkeyDefinition> get _customizable =>
    hotkeyDefinitions.where((d) => d.customizable).toList();

Set<HotkeyScope> get _customizableScopes =>
    _customizable.map((d) => d.scope).toSet();

Finder _resetButtons(String tooltip) => find.ancestor(
  of: find.byTooltip(tooltip),
  matching: find.byType(IconButton),
);

Finder _scopeHeading(String label) =>
    find.byWidgetPredicate((w) => w is Text && w.data == label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('HotkeysSettingsSection grouped layout', () {
    testWidgets('renders one card, tile, and header per scope group', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      final scopes = _customizableScopes;
      expect(scopes.length, greaterThan(1));

      expect(find.byType(EnjoyCard), findsNWidgets(scopes.length));
      expect(find.byType(EnjoyIconTile), findsNothing);

      for (final scope in scopes) {
        expect(
          find.text(hotkeysScopeLabel(l10n, scope)),
          findsOneWidget,
          reason: 'scope heading for $scope should render once',
        );
      }
    });

    testWidgets('separates scope groups with dividers inside each card', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      final dividers = find.byType(Divider);
      expect(
        dividers,
        findsNWidgets(_customizable.length - _customizableScopes.length),
      );
    });

    testWidgets('renders an EnjoyKeycap chord for every binding', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          overrides: [
            _override(const {'global.settings': 'ctrl+shift+k'}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KbdChordRow), findsNWidgets(_customizable.length));
      expect(find.byType(EnjoyKeycap), findsWidgets);
      expect(find.text('Ctrl'), findsWidgets);
      expect(find.text('Shift'), findsWidgets);
    });

    testWidgets('marks a customized binding and enables its reset action', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          overrides: [
            _override(const {'global.settings': 'ctrl+shift+k'}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyTierBadge), findsOneWidget);
      expect(find.text(l10n.hotkeysCustomizedBadge), findsOneWidget);

      final enabled = tester
          .widgetList<IconButton>(_resetButtons(l10n.hotkeysResetTooltip))
          .where((b) => b.onPressed != null);
      expect(enabled, hasLength(1));
    });

    testWidgets('disables reset and hides the badge for default bindings', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyTierBadge), findsNothing);
      expect(find.text(l10n.hotkeysCustomizedBadge), findsNothing);

      final resets = tester.widgetList<IconButton>(
        _resetButtons(l10n.hotkeysResetTooltip),
      );
      expect(resets, hasLength(_customizable.length));
      for (final reset in resets) {
        expect(reset.onPressed, isNull);
      }
    });

    testWidgets('rows are Aurora pressables under a NoSplash theme', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyPressable), findsNWidgets(_customizable.length));

      final theme = Theme.of(
        tester.element(find.byType(HotkeysSettingsSection)),
      );
      expect(theme.splashFactory, NoSplash.splashFactory);
    });

    testWidgets('filter narrows the grouped list to matching scopes', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      final allGroups = find.byType(EnjoyCard).evaluate().length;
      expect(allGroups, greaterThan(1));

      final target = _customizableScopes.first;
      final targetLabel = hotkeysScopeLabel(l10n, target);
      await tester.enterText(find.byType(TextField), targetLabel);
      await tester.pumpAndSettle();

      expect(_scopeHeading(targetLabel), findsOneWidget);
      expect(find.byType(EnjoyCard), findsOneWidget);
      for (final scope in _customizableScopes.where((s) => s != target)) {
        expect(_scopeHeading(hotkeysScopeLabel(l10n, scope)), findsNothing);
      }

      await tester.enterText(find.byType(TextField), 'zzzz-no-match');
      await tester.pumpAndSettle();

      expect(find.text(l10n.hotkeysHelpEmpty), findsOneWidget);
      expect(find.byType(EnjoyCard), findsNothing);
    });

    testWidgets('clear action restores the unfiltered list', (tester) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(overrides: [_override(const {})]));
      await tester.pumpAndSettle();

      final allGroups = find.byType(EnjoyCard).evaluate().length;

      await tester.enterText(find.byType(TextField), 'zzzz-no-match');
      await tester.pumpAndSettle();
      expect(find.byType(EnjoyCard), findsNothing);

      await tester.tap(find.byTooltip(l10n.settingsSearchClear));
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyCard).evaluate().length, allGroups);
    });
  });

  group('KbdChordRow', () {
    testWidgets('builds keycaps from the shared EnjoyKeycap primitive', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: KbdChordRow(binding: 'ctrl+shift+p')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyKeycap), findsNWidgets(3));
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('Shift'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
    });
  });
}
