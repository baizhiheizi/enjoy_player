/// Hosts global subscription tier reconciliation: refreshes the tier on app
/// resume + cold start and celebrates free → Pro transitions.
///
/// Mounted inside the authenticated shell ([RootShell]) so it is alive for
/// every authenticated screen. Renders its [child] unchanged — this widget
/// only adds side effects. See ADR-0041.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/tier_reconcile_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TierReconcileHost extends ConsumerStatefulWidget {
  const TierReconcileHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<TierReconcileHost> createState() => _TierReconcileHostState();
}

class _TierReconcileHostState extends ConsumerState<TierReconcileHost>
    with WidgetsBindingObserver {
  /// Last tier emitted by [currentTierProvider] while signed in, or `null`
  /// before a baseline is captured on sign-in. Used to detect genuine
  /// free → Pro transitions (and avoid re-celebrating while staying Pro).
  SubscriptionTier? _lastEmittedTier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    }
  }

  /// Captures the baseline tier + kicks off a background reconcile when already
  /// signed in at mount (auth resolved during bootstrap, before this widget's
  /// listeners attached). Also covers the cold-start case where the live tier
  /// has already advanced past the cached baseline by the time we mount.
  ///
  /// Uses [??=] so the [authCtrlProvider] listener (registered in [build]) can
  /// seed [_lastEmittedTier] first when auth resolves before the post-frame
  /// callback fires. Without this guard both paths can detect the same
  /// free→Pro transition independently, causing a double celebration.
  void _onFirstFrame() {
    if (!mounted) return;
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;
    _lastEmittedTier ??= auth.profile.subscriptionTier ?? SubscriptionTier.free;
    unawaited(ref.read(tierReconcileCtrlProvider.notifier).reconcile());
    final liveTier = ref.read(currentTierProvider);
    if (liveTier == SubscriptionTier.pro &&
        _lastEmittedTier != SubscriptionTier.pro) {
      _lastEmittedTier = liveTier;
      _celebrate();
    }
  }

  Future<void> _onResume() async {
    final notifier = ref.read(tierReconcileCtrlProvider.notifier);
    if (notifier.hasPendingPurchase) {
      await _eagerReconcile();
    } else {
      await notifier.reconcile();
    }
  }

  /// App-initiated purchase just returned: show a verifying notice, poll for
  /// confirmation, then celebrate or surface a soft timeout. The actual free
  /// → Pro celebration is also handled by the [currentTierProvider] listener,
  /// which dedupes via [_lastEmittedTier].
  Future<void> _eagerReconcile() async {
    final l10n = AppLocalizations.of(context)!;
    AppNotice.info(context, l10n.subscriptionVerifyingUpgrade);
    await ref.read(tierReconcileCtrlProvider.notifier).reconcile(eager: true);
    if (!mounted) return;
    if (ref.read(currentTierProvider) != SubscriptionTier.pro) {
      AppNotice.info(context, l10n.subscriptionVerifyTimeout);
    }
  }

  void _celebrate() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    AppNotice.success(context, l10n.subscriptionUpgradedToPro);
  }

  @override
  Widget build(BuildContext context) {
    // Capture the cached-profile tier as the baseline whenever the user (re)
    // signs in, so a stale "free" baseline from a previous session is reset.
    ref.listen<AsyncValue<AuthState>>(authCtrlProvider, (prev, next) {
      final prevAuth = prev?.valueOrNull;
      final nextAuth = next.valueOrNull;
      if (nextAuth is AuthSignedIn && prevAuth is! AuthSignedIn) {
        _lastEmittedTier =
            nextAuth.profile.subscriptionTier ?? SubscriptionTier.free;
        unawaited(ref.read(tierReconcileCtrlProvider.notifier).reconcile());
      } else if (nextAuth is! AuthSignedIn) {
        _lastEmittedTier = null;
      }
    });

    // Celebrate genuine free → Pro transitions only.
    ref.listen<SubscriptionTier>(currentTierProvider, (prev, next) {
      if (_lastEmittedTier == null) return;
      if (next == SubscriptionTier.pro &&
          _lastEmittedTier != SubscriptionTier.pro) {
        _celebrate();
      }
      _lastEmittedTier = next;
    });

    return widget.child;
  }
}
