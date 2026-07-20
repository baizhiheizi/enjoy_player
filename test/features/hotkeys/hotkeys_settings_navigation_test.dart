import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/settings/presentation/hotkeys_settings_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _RecordingHotkeysCtrl extends HotkeysCtrl {
  _RecordingHotkeysCtrl();

  static _RecordingHotkeysCtrl? last;

  var resetAllCalled = false;

  @override
  Future<Map<String, String>> build() async => const {
    'global.search': 'ctrl+k',
  };

  @override
  Future<void> resetAllBindings() async {
    resetAllCalled = true;
    state = const AsyncData({});
  }
}

Override _recordingHotkeysOverride() {
  return hotkeysCtrlProvider.overrideWith(() {
    final ctrl = _RecordingHotkeysCtrl();
    _RecordingHotkeysCtrl.last = ctrl;
    return ctrl;
  });
}

String? _keyboardSettingsRedirect(GoRouterState state) {
  final loc = state.matchedLocation;
  if (loc.startsWith('/settings/keyboard') && !isDesktop) {
    return '/settings';
  }
  if (loc == '/settings' &&
      state.uri.queryParameters['section'] == 'keyboard') {
    return isDesktop ? '/settings/keyboard' : null;
  }
  return null;
}

Widget _themedApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('keyboard settings routing', () {
    testWidgets('redirects /settings/keyboard to /settings on non-desktop', (
      tester,
    ) async {
      await _withPlatform(TargetPlatform.iOS, () async {
        final router = GoRouter(
          initialLocation: '/settings/keyboard',
          redirect: (_, state) => _keyboardSettingsRedirect(state),
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings-root')),
            ),
            GoRoute(
              path: '/settings/keyboard',
              builder: (_, _) =>
                  const Scaffold(body: Text('keyboard-settings')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('settings-root'), findsOneWidget);
        expect(find.text('keyboard-settings'), findsNothing);
      });
    });

    testWidgets('redirects legacy section=keyboard on desktop', (tester) async {
      await _withPlatform(TargetPlatform.windows, () async {
        final router = GoRouter(
          initialLocation: '/settings?section=keyboard',
          redirect: (_, state) => _keyboardSettingsRedirect(state),
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings-root')),
            ),
            GoRoute(
              path: '/settings/keyboard',
              builder: (_, _) =>
                  const Scaffold(body: Text('keyboard-settings')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('keyboard-settings'), findsOneWidget);
      });
    });
  });

  group('HotkeysSettingsScreen', () {
    testWidgets('shows filter and requires confirmation before reset all', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themedApp(
          overrides: [_recordingHotkeysOverride()],
          child: const HotkeysSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final ctrl = _RecordingHotkeysCtrl.last!;
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('GLOBAL'), findsOneWidget);
      expect(ctrl.resetAllCalled, isFalse);

      await tester.tap(find.text('Reset all shortcuts'));
      await tester.pumpAndSettle();

      expect(find.text('Reset all shortcuts?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(ctrl.resetAllCalled, isFalse);

      await tester.tap(find.text('Reset all shortcuts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset all shortcuts').last);
      await tester.pumpAndSettle();

      expect(ctrl.resetAllCalled, isTrue);
    });

    testWidgets('filter empty state when no shortcuts match', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          overrides: [_recordingHotkeysOverride()],
          child: const HotkeysSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzz-no-match');
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.hotkeysHelpEmpty), findsOneWidget);
      expect(find.text('GLOBAL'), findsNothing);
    });
  });

  group('HotkeysHelpDialog', () {
    testWidgets('customize pushes keyboard settings route', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => ElevatedButton(
              onPressed: () => showHotkeysHelpDialog(context),
              child: const Text('open-help'),
            ),
          ),
          GoRoute(
            path: '/settings/keyboard',
            builder: (_, _) => const HotkeysSettingsScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_recordingHotkeysOverride()],
          child: MaterialApp.router(
            theme: ThemeData(
              colorScheme: scheme,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-help'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customize shortcuts'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/settings/keyboard');
      expect(find.byType(HotkeysSettingsScreen), findsOneWidget);
    });

    testWidgets('search filters shortcuts and shows empty state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_recordingHotkeysOverride()],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showHotkeysHelpDialog(context),
                  child: const Text('open-help'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-help'));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      expect(find.text('GLOBAL'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz-no-match');
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.hotkeysHelpEmpty), findsOneWidget);
    });
  });
}
