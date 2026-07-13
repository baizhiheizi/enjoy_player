import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _StaticPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

/// Avoids real hardware/FFI microphone enumeration during widget tests,
/// which can hang or behave unpredictably outside a full Flutter engine.
class _FakeRecordingInputDeviceCtrl extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: [],
        selectedId: null,
        persistedId: null,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Player',
      packageName: 'com.enjoy.player.test',
      version: '0.3.1',
      buildNumber: '2',
      buildSignature: 'test',
    );
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpSettingsScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceGlobalAppDatabaseProvider.overrideWithValue(db),
          appDatabaseProvider.overrideWithValue(db),
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
          appPreferencesCtrlProvider.overrideWith(_StaticPrefsCtrl.new),
          recordingInputDeviceCtrlProvider.overrideWith(
            _FakeRecordingInputDeviceCtrl.new,
          ),
          syncQueueSnapshotProvider.overrideWith(
            (ref) => Stream.value(
              const SyncQueueSnapshot(
                retryablePending: 0,
                permanentlyFailed: 0,
                detailRows: [],
              ),
            ),
          ),
          syncLastFullSyncAtProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            brightness: Brightness.dark,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('en'));
  }

  testWidgets(
    'typing a query filters rows; all sections always expanded',
    (tester) async {
      final l10n = await pumpSettingsScreen(tester);

      // Developer is always expanded (no collapse header).
      expect(find.text(l10n.settingsAiPlaygroundTileTitle), findsOneWidget);
      // Before searching, other sections are also visible.
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'playground');
      await tester.pumpAndSettle();

      // "AI playground" matches the query and stays visible.
      expect(find.text(l10n.settingsAiPlaygroundTileTitle), findsOneWidget);
      // A section with no match is filtered out.
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a query matching nothing shows the no-results state with a working '
    'clear affordance that restores the prior view',
    (tester) async {
      final l10n = await pumpSettingsScreen(tester);

      await tester.enterText(
        find.byType(TextField),
        'zzz-nonexistent-setting-zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsSearchNoResultsTitle), findsOneWidget);
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsNothing);

      await tester.tap(find.text(l10n.settingsSearchClear));
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsSearchNoResultsTitle), findsNothing);
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
