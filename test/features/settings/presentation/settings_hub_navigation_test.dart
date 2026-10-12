/// Phone hub drill-in: tapping a hub section row pushes the section page and
/// renders that section's body under the subpage chrome.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_page.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/appearance_language_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/recording_section.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _fakeProfile = UserProfile(
  id: 'user-1',
  email: 'reader@example.com',
  name: 'Reader',
);

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _fakeProfile);
}

class _StaticPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

class _FakeRecordingInputDeviceCtrl extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: [],
        selectedId: null,
        persistedId: null,
      );
}

GoRouter _router() => GoRouter(
  initialLocation: '/settings',
  routes: [
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'appearance-language',
          builder: (_, _) => const SettingsSectionPageScreen(
            sectionId: SettingsSectionIds.appearanceLanguage,
          ),
        ),
        GoRoute(
          path: 'recording',
          builder: (_, _) => const SettingsSectionPageScreen(
            sectionId: SettingsSectionIds.recording,
          ),
        ),
      ],
    ),
  ],
);

Future<AppLocalizations> _pumpHub(WidgetTester tester, AppDatabase db) async {
  tester.view.physicalSize = const Size(390, 844);
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
        authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
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
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: scheme,
          useMaterial3: true,
          brightness: Brightness.dark,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('en'));
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

  testWidgets(
    'tapping Appearance & Language pushes the section page with its rows',
    (tester) async {
      final l10n = await _pumpHub(tester, db);

      expect(find.text(l10n.settingsSectionAppearanceLanguage), findsOneWidget);
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsNothing);

      await tester.tap(find.text(l10n.settingsSectionAppearanceLanguage));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsSectionPageScreen), findsOneWidget);
      expect(find.byType(AppearanceLanguageSectionBody), findsOneWidget);
      expect(find.text(l10n.settingsAppearanceDisplayLanguage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping Recording pushes the section page with the mic row', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, db);

    await tester.tap(find.text(l10n.settingsSectionRecording));
    await tester.pumpAndSettle();

    expect(find.byType(RecordingSectionBody), findsOneWidget);
    expect(find.text(l10n.settingsRecordingMicTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
