@Tags(['gallery'])
library;

import 'dart:async';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/core/routing/not_found_screen.dart';
import 'package:enjoy_player/features/ai/presentation/settings/ai_providers_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_edit_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_preferences_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_screen.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/sign_in_screen.dart';
import 'package:enjoy_player/features/craft/presentation/craft_history_screen.dart';
import 'package:enjoy_player/features/craft/presentation/craft_screen.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_screen.dart';
import 'package:enjoy_player/features/discover/presentation/discover_screen.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_actions.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/settings/presentation/hotkeys_settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/sync_status_screen.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/subscription/presentation/subscription_screen.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_session_screen.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'board_data.dart';
import 'fixtures.dart';
import 'gallery_support.dart';

class _FakeMic extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: [],
        selectedId: null,
        persistedId: null,
      );
}

class _SignedOut extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

var openHomeImportOnNextMount = false;
var openCheatsheetOnNextMount = false;

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  errorBuilder: (_, state) => NotFoundScreen(uri: state.uri),
  routes: [
    GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
    ShellRoute(
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              if (openHomeImportOnNextMount) {
                openHomeImportOnNextMount = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(showImportChooser(context, ref));
                  }
                });
              }
              return const HomeScreen();
            },
          ),
        ),
        GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
        GoRoute(
          path: '/vocabulary',
          builder: (_, _) => const VocabularyScreen(),
        ),
        GoRoute(
          path: '/vocabulary/review',
          builder: (_, _) => const VocabularyReviewSessionScreen(),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/settings/sync',
          builder: (_, _) => const SyncStatusScreen(),
        ),
        GoRoute(
          path: '/settings/keyboard',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              if (openCheatsheetOnNextMount) {
                openCheatsheetOnNextMount = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(showHotkeysHelpDialog(context));
                  }
                });
              }
              return const HotkeysSettingsScreen();
            },
          ),
        ),
        GoRoute(
          path: '/settings/ai-providers',
          builder: (_, _) => const AiProvidersScreen(),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const ProfileEditScreen(),
        ),
        GoRoute(
          path: '/profile/preferences',
          builder: (_, _) => const ProfilePreferencesScreen(),
        ),
        GoRoute(
          path: '/credits',
          builder: (_, _) => const CreditsUsageScreen(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (_, _) => const SubscriptionScreen(),
        ),
        GoRoute(path: '/craft', builder: (_, _) => const CraftScreen()),
        GoRoute(
          path: '/craft/history',
          builder: (_, _) => const CraftHistoryScreen(),
        ),
      ],
    ),
  ],
);

List<Override> _overrides(AppDatabase db, {bool signedOut = false}) => [
  ...boardOverrides(db, auth: signedOut ? _SignedOut.new : null),
  recordingInputDeviceCtrlProvider.overrideWith(_FakeMic.new),
];

/// Board → (route it opens on, subpage pushed on top, frame, brightness).
final _scenes = <(String, String, String?, GalleryFrame, Brightness)>[
  ('LibraryAudio', '/library', null, GalleryFrame.desktop, Brightness.light),
  ('Home', '/', null, GalleryFrame.desktop, Brightness.light),
  ('HomeDark', '/', null, GalleryFrame.desktop, Brightness.dark),
  ('Library', '/library', null, GalleryFrame.desktop, Brightness.light),
  ('Discover', '/discover', null, GalleryFrame.desktop, Brightness.light),
  ('Vocabulary', '/vocabulary', null, GalleryFrame.desktop, Brightness.light),
  ('Settings', '/settings', null, GalleryFrame.desktop, Brightness.light),
  ('SettingsDark', '/settings', null, GalleryFrame.desktop, Brightness.dark),
  (
    'Sync',
    '/settings',
    '/settings/sync',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  (
    'Keyboard',
    '/settings',
    '/settings/keyboard',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  (
    'AiProviders',
    '/settings',
    '/settings/ai-providers',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  ('Profile', '/profile', null, GalleryFrame.desktop, Brightness.light),
  (
    'ProfileEdit',
    '/profile',
    '/profile/edit',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  (
    'ProfilePrefs',
    '/profile',
    '/profile/preferences',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  ('Credits', '/profile', '/credits', GalleryFrame.desktop, Brightness.light),
  (
    'Subscription',
    '/profile',
    '/subscription',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  (
    'CraftHistory',
    '/',
    '/craft/history',
    GalleryFrame.desktop,
    Brightness.light,
  ),
  ('Craft', '/', '/craft', GalleryFrame.desktop, Brightness.light),
  ('SignIn', '/sign-in', null, GalleryFrame.desktop, Brightness.light),
  ('PhSignIn', '/sign-in', null, GalleryFrame.phone, Brightness.light),
  ('PhCraft', '/', '/craft', GalleryFrame.phone, Brightness.light),
  ('HomeImport', '/', null, GalleryFrame.desktop, Brightness.light),
  (
    'KeyboardCheatsheet',
    '/settings/keyboard',
    null,
    GalleryFrame.desktop,
    Brightness.light,
  ),
  ('NotFound', '/no-such-route', null, GalleryFrame.desktop, Brightness.light),
  (
    'Review',
    '/vocabulary/review',
    null,
    GalleryFrame.desktop,
    Brightness.light,
  ),
  ('PhHome', '/', null, GalleryFrame.phone, Brightness.light),
  ('PhHomeDark', '/', null, GalleryFrame.phone, Brightness.dark),
  ('PhLibrary', '/library', null, GalleryFrame.phone, Brightness.light),
  ('PhDiscover', '/discover', null, GalleryFrame.phone, Brightness.light),
  ('PhVocabulary', '/vocabulary', null, GalleryFrame.phone, Brightness.light),
  ('PhProfile', '/profile', null, GalleryFrame.phone, Brightness.light),
  ('PhSettings', '/settings', null, GalleryFrame.phone, Brightness.light),
];

void main() {
  setUpAll(setUpGallery);
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Player',
      packageName: 'ai.enjoy.player',
      version: '0.9.0',
      buildNumber: '15',
      buildSignature: 'x',
    );
  });

  for (final (board, route, pushed, frame, brightness) in _scenes) {
    testWidgets(board, (tester) async {
      openHomeImportOnNextMount = board == 'HomeImport';
      openCheatsheetOnNextMount = board == 'KeyboardCheatsheet';
      final db = memoryDb();
      await tester.runAsync(() => seedBoardData(db));
      final router = _router(route);
      await shootBoard(
        tester,
        board,
        sceneApp(
          router: router,
          overrides: _overrides(db, signedOut: board.endsWith('SignIn')),
          brightness: brightness,
        ),
        frame: frame,
        db: db,
        before: switch (board) {
          'LibraryAudio' => (tester) async {
            await tester.tap(find.text('Audio'));
            await tester.enterText(find.byType(TextField).last, 'ferry');
          },
          _ =>
            pushed == null
                ? null
                : (tester) async => unawaited(router.push(pushed)),
        },
      );
    });
  }
}
