/// Bootstrap automatic sync when the user session is active.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/sync/application/rekey_local_rows.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

part 'sync_controller.g.dart';

final _log = logNamed('sync');

@Riverpod(keepAlive: true)
class SyncCtrl extends _$SyncCtrl {
  Timer? _periodic;

  @override
  int build() {
    ref.onDispose(() {
      _periodic?.cancel();
      _periodic = null;
    });

    ref.listen(authCtrlProvider, (previous, next) {
      final prevIn = previous?.valueOrNull is AuthSignedIn;
      final nextIn = next.valueOrNull is AuthSignedIn;
      if (nextIn && !prevIn) {
        unawaited(_onSignedIn());
      }
      if (!nextIn && prevIn) {
        _periodic?.cancel();
        _periodic = null;
      }
    });

    return 0;
  }

  Future<void> _onSignedIn() async {
    try {
      final auth = ref.read(authCtrlProvider).valueOrNull;
      if (auth is AuthSignedIn) {
        await rekeyLocalMediaRowsOnSignIn(
          db: ref.read(appDatabaseProvider),
          userId: auth.profile.id,
          enqueue: ref.read(syncEnqueueProvider),
        );
      }
      final result =
          await ref.read(syncEngineProvider).fullSync(const SyncOptions());
      await _persistLastFullSyncTimestamp(result);
    } catch (e, st) {
      _log.warning('fullSync on sign-in failed', e, st);
    }

    _periodic?.cancel();
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_periodicDrain());
    });
  }

  Future<void> _periodicDrain() async {
    if (ref.read(authCtrlProvider).valueOrNull is! AuthSignedIn) return;
    try {
      await ref.read(syncEngineProvider).processQueue(const SyncOptions());
    } catch (e, st) {
      _log.warning('periodic sync drain failed', e, st);
    }
  }

  /// Non-blocking queue drain when already signed in.
  void kickDrain() {
    if (ref.read(authCtrlProvider).valueOrNull is! AuthSignedIn) return;
    unawaited(() async {
      try {
        await ref.read(syncEngineProvider).processQueue(const SyncOptions());
      } catch (e, st) {
        _log.warning('kickDrain failed', e, st);
      }
    }());
  }

  Future<SyncResult> triggerSync({bool resetFailed = false}) async {
    if (ref.read(authCtrlProvider).valueOrNull is! AuthSignedIn) {
      return const SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        errors: ['Signed out'],
      );
    }
    final result = await ref
        .read(syncEngineProvider)
        .fullSync(SyncOptions(resetFailed: resetFailed));
    await _persistLastFullSyncTimestamp(result);
    return result;
  }

  Future<void> _persistLastFullSyncTimestamp(SyncResult result) async {
    if (!result.success) return;
    try {
      await ref.read(appDatabaseProvider).settingsDao.setValue(
            SettingsKeys.syncLastFullSyncAt,
            DateTime.now().toUtc().toIso8601String(),
          );
      ref.invalidate(syncLastFullSyncAtProvider);
    } catch (e, st) {
      _log.warning('persist sync.last_full_sync_at failed', e, st);
    }
  }
}
