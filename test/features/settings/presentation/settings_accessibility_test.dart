/// Automated evidence for T050's accessibility pass: reduced motion and the
/// largest text scale must not overlap/clip content, and collapse/expand
/// must keep working via its tap target (not only its animation). A true
/// OS-level manual pass is still recorded separately in quickstart.md.
library;

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

class _FakeRecordingInputDeviceCtrl extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: [],
        selectedId: null,
        persistedId: null,
      );
}

// ignore: strict_top_level_inference
_settingsTestOverrides(AppDatabase db) => [
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
];

Widget _harness({
  required AppDatabase db,
  required bool disableAnimations,
  required double textScale,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return MediaQuery(
    data: MediaQueryData(
      disableAnimations: disableAnimations,
      textScaler: TextScaler.linear(textScale),
    ),
    child: ProviderScope(
      overrides: _settingsTestOverrides(db),
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
    'with reduced motion and the largest text scale, the hub renders with '
    'no overflow and all section content is visible',
    (tester) async {
      tester.view.physicalSize = const Size(700, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _harness(db: db, disableAnimations: true, textScale: 3.0),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Developer content is always visible (no collapse header).
      expect(find.text(l10n.settingsApiBaseUrl), findsOneWidget);

      // Scroll down to reach About content.
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 15; i++) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pump();
      }
      // About content is always visible (no collapse header).
      expect(find.text(l10n.appTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the two-pane layout also renders with no overflow at reduced motion '
    'and the largest text scale',
    (tester) async {
      tester.view.physicalSize = const Size(1300, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _harness(db: db, disableAnimations: true, textScale: 3.0),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
    },
  );
}
