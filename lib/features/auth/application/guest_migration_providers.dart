/// Guest → signed-in user local data migration (per-user Drift files).
library;

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';

part 'guest_migration_providers.g.dart';

final Logger _log = logNamed('guest_migration');

/// `true` when the guest DB has at least one row in library or practice tables.
@Riverpod(keepAlive: true)
Future<bool> guestDatabaseHasData(Ref ref) async {
  final guest = ref.watch(guestAppDatabaseProvider);
  return _guestHasMigratableData(guest);
}

/// Banner: signed in, guest has data, user has not dismissed.
@Riverpod(keepAlive: true)
Future<bool> showGuestMigrationBanner(Ref ref) async {
  final auth = ref.watch(authCtrlProvider);
  final signedIn = auth.maybeWhen(
    data: (s) => s is AuthSignedIn,
    orElse: () => false,
  );
  if (!signedIn) return false;

  final hasGuest = await ref.watch(guestDatabaseHasDataProvider.future);
  if (!hasGuest) return false;

  final dismissed = await ref.watch(appDatabaseProvider).settingsDao.getValue(
        SettingsKeys.migrationGuestDismissed,
      );
  if (dismissed == 'true') return false;
  return true;
}

@Riverpod(keepAlive: true)
class GuestMigrationCtrl extends _$GuestMigrationCtrl {
  @override
  FutureOr<void> build() {}

  /// Copies guest rows into the signed-in user's DB, then clears guest data tables
  /// (preserves `api.base_url` and other settings on the guest DB).
  Future<void> migrate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authCtrlProvider).valueOrNull;
      if (auth is! AuthSignedIn) {
        throw StateError('migrate called while not signed in');
      }
      final guest = ref.read(guestAppDatabaseProvider);
      final user = ref.read(appDatabaseProvider);
      if (identical(guest, user)) {
        throw StateError('migrate requires a user-scoped database');
      }

      await _migrateGuestToUser(guest: guest, user: user);
      _log.info('guest migration completed for user ${auth.profile.id}');

      await ref.read(appDatabaseProvider).settingsDao.setValue(
            SettingsKeys.migrationGuestDismissed,
            '',
          );

      ref.invalidate(guestDatabaseHasDataProvider);
      ref.invalidate(showGuestMigrationBannerProvider);
      ref.invalidate(libraryMediaProvider);
      ref.invalidate(syncQueueSnapshotProvider);
    });
    if (state.hasError) return;
    state = const AsyncData(null);
  }

  Future<void> dismiss() async {
    await ref.read(appDatabaseProvider).settingsDao.setValue(
          SettingsKeys.migrationGuestDismissed,
          'true',
        );
    ref.invalidate(showGuestMigrationBannerProvider);
  }
}

Future<bool> _guestHasMigratableData(AppDatabase guest) async {
  final row = await guest.customSelect(
    r'''
SELECT (
  EXISTS(SELECT 1 FROM videos LIMIT 1) OR
  EXISTS(SELECT 1 FROM audios LIMIT 1) OR
  EXISTS(SELECT 1 FROM transcripts LIMIT 1) OR
  EXISTS(SELECT 1 FROM echo_sessions LIMIT 1) OR
  EXISTS(SELECT 1 FROM recordings LIMIT 1) OR
  EXISTS(SELECT 1 FROM dictations LIMIT 1) OR
  EXISTS(SELECT 1 FROM sync_queue LIMIT 1)
) AS has_data
''',
    readsFrom: {
      guest.videos,
      guest.audios,
      guest.transcripts,
      guest.echoSessions,
      guest.recordings,
      guest.dictations,
      guest.syncQueue,
    },
  ).getSingle();

  final v = row.data['has_data'];
  if (v is bool) return v;
  if (v is int) return v != 0;
  return false;
}

Future<void> _migrateGuestToUser({
  required AppDatabase guest,
  required AppDatabase user,
}) async {
  final videos = await guest.select(guest.videos).get();
  final audios = await guest.select(guest.audios).get();
  final transcripts = await guest.select(guest.transcripts).get();
  final echoSessions = await guest.select(guest.echoSessions).get();
  final recordings = await guest.select(guest.recordings).get();
  final dictations = await guest.select(guest.dictations).get();
  final syncRows = await guest.select(guest.syncQueue).get();

  await user.batch((b) {
    for (final r in videos) {
      b.insert(user.videos, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in audios) {
      b.insert(user.audios, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in transcripts) {
      b.insert(user.transcripts, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in echoSessions) {
      b.insert(user.echoSessions, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in recordings) {
      b.insert(user.recordings, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in dictations) {
      b.insert(user.dictations, r, mode: InsertMode.insertOrReplace);
    }
    for (final r in syncRows) {
      b.insert(
        user.syncQueue,
        SyncQueueCompanion.insert(
          entityType: r.entityType,
          entityId: r.entityId,
          action: r.action,
          payloadJson: Value(r.payloadJson),
          retryCount: Value(r.retryCount),
          lastAttempt: Value(r.lastAttempt),
          error: Value(r.error),
          createdAt: r.createdAt,
        ),
      );
    }
  });

  const dataTables = <String>[
    'videos',
    'audios',
    'transcripts',
    'echo_sessions',
    'recordings',
    'dictations',
    'sync_queue',
  ];
  for (final name in dataTables) {
    await guest.customStatement('DELETE FROM $name');
  }
}
