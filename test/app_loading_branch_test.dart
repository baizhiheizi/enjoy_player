import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/app.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/sign_in_screen.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

/// Resolves preferences immediately but never resolves auth, so
/// `authCtrlProvider` stays in `AsyncLoading` without a previous value —
/// the exact window [EnjoyApp] must cover with the bootstrap skeleton
/// instead of letting the router render (issue #810 B2).
class _NeverCompletingAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() => Completer<AuthState>().future;
}

/// Builds successfully but the returned [Future] never resolves, so
/// `appPreferencesCtrlProvider` stays in `AsyncLoading` for the whole
/// test — exactly what the loading branch of [EnjoyApp] is supposed to
/// handle.
class _NeverCompletingPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async {
    return Completer<AppPreferencesState>().future;
  }
}

class _NoopUpdateCtrl extends UpdateCtrl {
  @override
  UpdateCheckResult? build() => null;

  @override
  Future<void> bootstrap() async {}
}

class _ImmediateDefaultsPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'EnjoyApp loading branch renders the skeleton with a localized context '
    'instead of crashing on a missing AppLocalizations delegate',
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
        'enjoy_app_loading_branch',
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
              _NeverCompletingPrefsCtrl.new,
            ),
            updateCtrlProvider.overrideWith(_NoopUpdateCtrl.new),
            playerEngineTestDoubleProvider.overrideWithValue(fakeEngine),
          ],
          child: const EnjoyApp(themeBuilder: _testTheme),
        ),
      );

      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fakeEngine.dispose();
      await db.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    },
  );

  testWidgets(
    'EnjoyApp keeps the bootstrap skeleton (no sign-in flash, no router '
    'content) while the initial auth state is loading',
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
        'enjoy_app_auth_loading',
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
            authCtrlProvider.overrideWith(_NeverCompletingAuthCtrl.new),
            appPreferencesCtrlProvider.overrideWith(
              _ImmediateDefaultsPrefsCtrl.new,
            ),
            updateCtrlProvider.overrideWith(_NoopUpdateCtrl.new),
            playerEngineTestDoubleProvider.overrideWithValue(fakeEngine),
          ],
          child: const EnjoyApp(themeBuilder: _testTheme),
        ),
      );

      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(find.byType(SkeletonAppBootstrap), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(SignInScreen), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fakeEngine.dispose();
      await db.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    },
  );
}
