/// Reconciles the subscription tier with the server on app resume and cold
/// start, and owns the app-initiated purchase "pending" flag for eager polling.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';

part 'tier_reconcile_provider.g.dart';

final Logger _log = logNamed('subscription.reconcile');

/// Minimum gap between non-eager reconciles to avoid hammering the API on
/// rapid background/foreground toggles (e.g. battery saver).
const _reconcileDebounce = Duration(seconds: 30);

/// Eager-poll cadence and budget after an app-initiated purchase.
const _eagerPollInterval = Duration(seconds: 3);
const _eagerPollTimeout = Duration(seconds: 30);

/// Orchestrates tier reconciliation between the app and the Enjoy API.
///
/// Reconciliation refreshes *both* sources of truth consumed by
/// [currentTierProvider]: the cached profile ([authCtrlProvider], via
/// [AuthCtrl.refreshProfile]) and the live status
/// ([subscriptionStatusProvider]). This guarantees a tier change made on the
/// web (with or without an app-initiated checkout) surfaces in the app on the
/// next resume or cold start — see ADR-0041.
@Riverpod(keepAlive: true)
class TierReconcileCtrl extends _$TierReconcileCtrl {
  DateTime? _lastReconciledAt;
  bool _reconciling = false;
  bool _purchasePending = false;

  @override
  void build() {}

  /// Whether an app-initiated purchase is awaiting confirmation.
  bool get hasPendingPurchase => _purchasePending;

  /// Mark that the user just launched external checkout from the app. The next
  /// resume will reconcile eagerly (polling for confirmation).
  void markPurchasePending() {
    _purchasePending = true;
  }

  /// Refresh the tier from the server.
  ///
  /// When [eager] (app-initiated purchase just returned), poll the status
  /// endpoint until the tier flips to [SubscriptionTier.pro] or
  /// [_eagerPollTimeout] elapses, then clears the pending flag. Otherwise a
  /// single fan-out refresh, debounced by [_reconcileDebounce]. Always a no-op
  /// when signed out; transient network errors are swallowed and logged so a
  /// flaky connection never signs the user out.
  Future<void> reconcile({bool eager = false}) async {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;

    if (_reconciling) {
      _log.fine('reconcile already in progress; skipping');
      return;
    }
    if (!eager) {
      final last = _lastReconciledAt;
      if (last != null &&
          DateTime.now().difference(last) < _reconcileDebounce) {
        _log.fine('reconcile debounced; skipping');
        return;
      }
    }

    _reconciling = true;
    try {
      if (eager) {
        await _pollUntilProOrTimeout();
        _purchasePending = false;
      } else {
        await _refreshOnce();
      }
      _lastReconciledAt = DateTime.now();
    } finally {
      _reconciling = false;
    }
  }

  /// Fan out to both sources of truth: invalidate + await the live status, and
  /// refresh the cached profile (which also rewrites the secure-storage cache).
  Future<void> _refreshOnce() async {
    ref.invalidate(subscriptionStatusProvider);
    await Future.wait([_safeStatusFetch(), _safeProfileRefresh()]);
  }

  Future<void> _safeStatusFetch() async {
    try {
      await ref.read(subscriptionStatusProvider.future);
    } catch (e, st) {
      _log.warning('reconcile: status fetch failed', e, st);
    }
  }

  Future<void> _safeProfileRefresh() async {
    try {
      await ref.read(authCtrlProvider.notifier).refreshProfile();
    } catch (e, st) {
      _log.warning('reconcile: profile refresh failed', e, st);
    }
  }

  Future<void> _pollUntilProOrTimeout() async {
    final deadline = DateTime.now().add(_eagerPollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      ref.invalidate(subscriptionStatusProvider);
      final confirmed = await _pollOnce();
      if (confirmed) return;
      await Future<void>.delayed(_eagerPollInterval);
    }
    _log.info(
      'eager reconcile timed out before Pro confirmed; '
      'background reconcile will retry',
    );
  }

  /// Fetch the status once; also refresh the profile so the cache catches up.
  /// Returns true when the tier has flipped to Pro.
  Future<bool> _pollOnce() async {
    try {
      final status = await ref.read(subscriptionStatusProvider.future);
      if (status.subscriptionTier == SubscriptionTier.pro) {
        await _safeProfileRefresh();
        return true;
      }
    } catch (e, st) {
      _log.warning('eager reconcile: status fetch failed', e, st);
    }
    return false;
  }
}
