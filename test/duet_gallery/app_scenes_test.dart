@Tags(['gallery'])
library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

GoRouter _shellRouter(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);

Future<List<Override>> _settingsOverrides(AppDatabase db) async => [
  ...baseOverrides(db),
  profilePracticeStatsProvider.overrideWith(
    (ref) async => const LearningStatistics(
      today: PeriodStats(recordingDurationMs: 142000, recordingCount: 12),
      week: PeriodStats(recordingDurationMs: 2400000, recordingCount: 88),
      month: PeriodStats(recordingDurationMs: 9400000, recordingCount: 301),
    ),
  ),
  vocabularyStatsProvider.overrideWithValue(
    const VocabularyStats(
      total: 120,
      due: 14,
      newCount: 10,
      learningCount: 40,
      reviewingCount: 50,
      masteredCount: 20,
    ),
  ),
  recordingInputDeviceCtrlProvider.overrideWith(_FakeMic.new),
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

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.dark ? 'Dark' : '';
    for (final (route, board) in [
      ('/', 'Home'),
      ('/library', 'Library'),
      ('/settings', 'Settings'),
    ]) {
      testWidgets('$board$suffix', (tester) async {
        final db = memoryDb();
        await shootBoard(
          tester,
          '$board$suffix',
          sceneApp(
            router: _shellRouter(route),
            overrides: await _settingsOverrides(db),
            brightness: brightness,
          ),
          db: db,
        );
      });
    }
  }
}
