/// Bootstrap automatic sync when the user session is active.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
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

/// How many post-frame retries `_onSignedIn` will run while
/// `appDatabaseProvider` is still serving the guest DB after the auth
/// state has flipped. Beyond this we log and skip the rekey (the
/// per-user DB will be ready by the time the periodic drain fires).
const _kSignInDbResolveMaxFrames = 5;

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_onSignedIn());
        });
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
      if (auth is! AuthSignedIn) return;

      // Riverpod's provider rebuild is scheduled, not synchronous: when
      // `authCtrlProvider` flips to AuthSignedIn, the `appDatabaseProvider`
      // selector picks up the per-user file name on the next microtask.
      // If we `ref.read(appDatabaseProvider)` immediately, we can still
      // get the guest DB. Defer to a post-frame + a microtask and then
      // re-check; retry up to [_kSignInDbResolveMaxFrames] frames before
      // giving up and logging.
      for (var attempt = 0;
          attempt < _kSignInDbResolveMaxFrames;
          attempt++) {
        await Future<void>.delayed(Duration.zero);
        if (ref.read(authCtrlProvider).valueOrNull is! AuthSignedIn) return;
        final db = ref.read(appDatabaseProvider);
        if (!db.isGuestDatabase) {
          await rekeyLocalMediaRowsOnSignIn(
            db: db,
            userId: auth.profile.id,
            enqueue: ref.read(syncEnqueueProvider),
          );
          await Future<void>.delayed(Duration.zero);
          final result = await ref
              .read(syncEngineProvider)
              .fullSync(const SyncOptions());
          await _persistLastFullSyncTimestamp(result);
          return;
        }
      }
      _log.warning(
        'sync on sign-in skipped: appDatabaseProvider still serves the '
        'guest DB after $_kSignInDbResolveMaxFrames frames; '
        'user=${auth.profile.id}',
      );
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
      await ref
          .read(appDatabaseProvider)
          .settingsDao
          .setValue(
            SettingsKeys.syncLastFullSyncAt,
            DateTime.now().toUtc().toIso8601String(),
          );
      ref.invalidate(syncLastFullSyncAtProvider);
    } catch (e, st) {
      _log.warning('persist sync.last_full_sync_at failed', e, st);
    }
  }
}
