@Tags(['gallery'])
library;

import 'dart:async';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/ai/presentation/settings/ai_providers_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_edit_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_preferences_screen.dart';
import 'package:enjoy_player/features/auth/presentation/profile_screen.dart';
import 'package:enjoy_player/features/craft/presentation/craft_history_screen.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_screen.dart';
import 'package:enjoy_player/features/discover/presentation/discover_screen.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/settings/presentation/hotkeys_settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/sync_status_screen.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/subscription/presentation/subscription_screen.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_screen.dart';
import 'package:flutter/material.dart';
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

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
        GoRoute(
          path: '/vocabulary',
          builder: (_, _) => const VocabularyScreen(),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/settings/sync',
          builder: (_, _) => const SyncStatusScreen(),
        ),
        GoRoute(
          path: '/settings/keyboard',
          builder: (_, _) => const HotkeysSettingsScreen(),
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
        GoRoute(
          path: '/craft/history',
          builder: (_, _) => const CraftHistoryScreen(),
        ),
      ],
    ),
  ],
);

List<Override> _overrides(AppDatabase db) => [
  ...boardOverrides(db),
  recordingInputDeviceCtrlProvider.overrideWith(_FakeMic.new),
];

/// Board → (route it opens on, subpage pushed on top, frame, brightness).
final _scenes = <(String, String, String?, GalleryFrame, Brightness)>[
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
      final db = memoryDb();
      await tester.runAsync(() => seedBoardData(db));
      final router = _router(route);
      await shootBoard(
        tester,
        board,
        sceneApp(
          router: router,
          overrides: _overrides(db),
          brightness: brightness,
        ),
        frame: frame,
        db: db,
        before: pushed == null
            ? null
            : (tester) async => unawaited(router.push(pushed)),
      );
    });
  }
}
