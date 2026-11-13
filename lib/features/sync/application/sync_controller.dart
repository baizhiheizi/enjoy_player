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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_onSignedIn());
        });
      }
      if (!nextIn && prevIn) {
        _periodic?.cancel();
        _periodic = null;
      }
    });

    if (ref.read(authCtrlProvider).valueOrNull is AuthSignedIn) {
      unawaited(
        Future<void>.delayed(Duration.zero, () {
          unawaited(_onSignedIn());
        }),
      );
    }

    return 0;
  }

  Future<void> _onSignedIn() async {
    try {
      final auth = ref.read(authCtrlProvider).valueOrNull;
      if (auth is! AuthSignedIn) return;

      await Future<void>.delayed(Duration.zero);
      final result = await ref
          .read(syncEngineProvider)
          .fullSync(const SyncOptions());
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
    if (!_isAppResumed) {
      _log.fine('periodic sync drain skipped: app is not in foreground');
      return;
    }
    try {
      final result = await ref
          .read(syncEngineProvider)
          .fullSync(const SyncOptions());
      await _persistLastFullSyncTimestamp(result);
    } catch (e, st) {
      _log.warning('periodic sync drain failed', e, st);
    }
  }

  /// Pulls vocabulary items + contexts from the server without draining the
  /// upload queue. Signed-out callers get a failed result instead of a
  /// network call; a thrown pull is reported as one failed unit.
  Future<SyncResult> pullVocabulary() async {
    if (ref.read(authCtrlProvider).valueOrNull is! AuthSignedIn) {
      return const SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        errors: ['Signed out'],
      );
    }
    try {
      return await ref.read(syncEngineProvider).pullVocabulary();
    } catch (e, st) {
      _log.warning('pullVocabulary failed', e, st);
      return const SyncResult(
        success: false,
        synced: 0,
        failed: 1,
        errors: ['vocabulary pull failed'],
      );
    }
  }

  /// Whether the app is currently in the foreground. `null` is treated as
  /// "resumed" so platforms that do not publish a lifecycle state still drain.
  bool get _isAppResumed {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
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
          .writeSetting(
            SettingsKeys.syncLastFullSyncAt,
            DateTime.now().toUtc().toIso8601String(),
          );
      ref.invalidate(syncLastFullSyncAtProvider);
    } catch (e, st) {
      _log.warning('persist sync.last_full_sync_at failed', e, st);
    }
  }
}
