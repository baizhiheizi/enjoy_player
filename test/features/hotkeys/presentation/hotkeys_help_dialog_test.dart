import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHotkeysCtrl extends HotkeysCtrl {
  _FakeHotkeysCtrl(this._bindings);

  final Map<String, String> _bindings;

  @override
  Future<Map<String, String>> build() async => Map.of(_bindings);
}

Widget _app(Map<String, String> bindings) {
  return ProviderScope(
    overrides: [
      hotkeysCtrlProvider.overrideWith(() => _FakeHotkeysCtrl(bindings)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HotkeysHelpDialog()),
    ),
  );
}

Finder _scopeHeading(String label) => find.text(label.toUpperCase());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('HotkeysHelpDialog', () {
    testWidgets('renders every definition grouped under its scope', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(const {}));
      await tester.pumpAndSettle();

      expect(find.byType(KbdChordRow), findsNWidgets(hotkeyDefinitions.length));
      for (final scope in HotkeyScope.values) {
        expect(
          _scopeHeading(hotkeysScopeLabel(l10n, scope)),
          findsOneWidget,
          reason: 'scope heading for $scope should render once',
        );
      }
    });

    testWidgets('marks customized bindings with the shared muted tier badge', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(const {'global.settings': 'ctrl+shift+k'}));
      await tester.pumpAndSettle();

      expect(find.byType(EnjoyTierBadge), findsOneWidget);
      expect(find.text(l10n.hotkeysCustomizedBadge), findsOneWidget);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('filter narrows sections and shows the empty state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(const {}));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'settings');
      await tester.pumpAndSettle();

      expect(
        _scopeHeading(hotkeysScopeLabel(l10n, HotkeyScope.global)),
        findsOneWidget,
      );
      expect(
        _scopeHeading(hotkeysScopeLabel(l10n, HotkeyScope.player)),
        findsNothing,
      );
      expect(find.text('Open settings'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz-no-match');
      await tester.pumpAndSettle();

      expect(find.text(l10n.hotkeysHelpEmpty), findsOneWidget);
      expect(find.byType(KbdChordRow), findsNothing);
    });
  });
}
