import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/app.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_surface.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'support/fake_player_engine.dart';
import 'support/test_path_provider.dart';

ThemeData _testTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: [EnjoyThemeTokens.build(scheme)],
  );
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _NoopUpdateCtrl extends UpdateCtrl {
  @override
  UpdateCheckResult? build() => null;

  @override
  Future<void> bootstrap() async {}
}

/// Always fails — used by the widget-level test, which only needs to
/// confirm [RecoverySurface] renders (never actually taps through reset;
/// see `performRecoveryReset` below for that coverage).
class _AlwaysFailingPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async {
    throw Exception(
      'SqliteException(1): while executing, duplicate column name: '
      'duration_seconds, SQL logic error (code 1)',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'EnjoyApp shows a localized RecoverySurface for a stale/corrupt local '
    'DB instead of crashing on a missing AppLocalizations delegate',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Enjoy Player',
        packageName: 'com.enjoy.player.test',
        version: '0.3.1',
        buildNumber: '2',
        buildSignature: 'test',
      );

      final root = Directory.systemTemp.createTempSync(
        'enjoy_app_recovery_flow',
      );
      PathProviderPlatform.instance = TestPathProvider(root.path);

      final db = AppDatabase(executor: NativeDatabase.memory());
      final fakeEngine = FakePlayerEngine();

      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceGlobalAppDatabaseProvider.overrideWithValue(db),
            appDatabaseProvider.overrideWithValue(db),
            authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
            appPreferencesCtrlProvider.overrideWith(
              _AlwaysFailingPrefsCtrl.new,
            ),
            updateCtrlProvider.overrideWith(_NoopUpdateCtrl.new),
            playerEngineTestDoubleProvider.overrideWithValue(fakeEngine),
            syncEnqueueProvider.overrideWithValue((_, _, _) async {}),
            libraryHomeRecentsProvider.overrideWith(
              (ref) => Stream<List<Media>>.value(const []),
            ),
            discoverSubscriptionsProvider.overrideWith(
              (ref) => Stream<List<DiscoverChannel>>.value(const []),
            ),
          ],
          child: const EnjoyApp(themeBuilder: _testTheme),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      expect(find.text('Local data needs attention'), findsOneWidget);
      expect(find.text('Reset local library'), findsAtLeastNWidgets(1));
      expect(find.text('Copy error'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fakeEngine.dispose();
      await db.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    },
  );

  group('performRecoveryReset', () {
    late Directory root;
    late Directory docsDir;
    late Directory supportDir;

    setUp(() {
      root = Directory.systemTemp.createTempSync('perform_recovery_reset_');
      docsDir = Directory(p.join(root.path, 'documents'))
        ..createSync(recursive: true);
      supportDir = Directory(p.join(root.path, 'support'))
        ..createSync(recursive: true);
      PathProviderPlatform.instance = TestPathProvider(
        docsDir.path,
        supportPath: supportDir.path,
      );
    });

    tearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test(
      'wipes the device-global DB file and invalidates DB + prefs providers on '
      'success',
      () async {
        final deviceGlobalDbFile = File(
          p.join(
            docsDir.path,
            '${AppDatabase.deviceGlobalDatabaseName}.sqlite',
          ),
        );
        deviceGlobalDbFile.writeAsStringSync('not-a-real-sqlite-file');

        var prefsBuildCount = 0;
        final container = ProviderContainer(
          overrides: [
            appPreferencesCtrlProvider.overrideWith(() {
              return _CountingPrefsCtrl(() => prefsBuildCount++);
            }),
          ],
        );
        addTearDown(container.dispose);

        container.listen(appDatabaseProvider, (_, _) {});
        container.listen(
          appPreferencesCtrlProvider,
          (_, _) {},
          fireImmediately: true,
        );
        await container.read(appPreferencesCtrlProvider.future).catchError((_) {
          return AppPreferencesState.initial;
        });
        expect(prefsBuildCount, 1);

        final outcome = await container.read(
          recoveryResetResultProvider.future,
        );

        expect(outcome, RecoveryResetOutcome.success);
        expect(deviceGlobalDbFile.existsSync(), isFalse);
        await container.read(appPreferencesCtrlProvider.future).catchError((_) {
          return AppPreferencesState.initial;
        });
        expect(prefsBuildCount, 2);
      },
    );

    test(
      'returns backupFailed and touches nothing when no DB exists',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final outcome = await container.read(
          recoveryResetResultProvider.future,
        );

        expect(outcome, RecoveryResetOutcome.backupFailed);
      },
    );
  });
}

class _CountingPrefsCtrl extends AppPreferencesCtrl {
  _CountingPrefsCtrl(this._onBuild);
  final void Function() _onBuild;

  @override
  Future<AppPreferencesState> build() async {
    _onBuild();
    return AppPreferencesState.initial;
  }
}
