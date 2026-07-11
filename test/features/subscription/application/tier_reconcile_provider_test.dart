import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/application/tier_reconcile_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _freeProfile = UserProfile(
  id: 'u1',
  email: 'a@b.com',
  name: 'Free',
  subscriptionTier: SubscriptionTier.free,
);
const _proStatus = SubscriptionStatus(
  subscriptionActive: true,
  subscriptionTier: SubscriptionTier.pro,
);
const _freeStatus = SubscriptionStatus(
  subscriptionActive: true,
  subscriptionTier: SubscriptionTier.free,
);

/// Signed-in auth whose [AuthCtrl.refreshProfile] is a no-op recording stub,
/// so reconcile can be exercised without a real network/repository.
class _RecordingAuthCtrl extends AuthCtrl {
  int refreshCalls = 0;

  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _freeProfile);

  @override
  Future<void> refreshProfile() async {
    refreshCalls++;
  }
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reconcile is a no-op when signed out (status never fetched)', () async {
    var statusCalls = 0;
    final container = ProviderContainer(
      overrides: [
        authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
        subscriptionStatusProvider.overrideWith((ref) async {
          statusCalls++;
          return _proStatus;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);

    await container.read(tierReconcileCtrlProvider.notifier).reconcile();

    expect(statusCalls, 0);
  });

  test(
    'non-eager reconcile refreshes profile + status when signed in',
    () async {
      var statusCalls = 0;
      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_RecordingAuthCtrl.new),
          subscriptionStatusProvider.overrideWith((ref) async {
            statusCalls++;
            return _proStatus;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      final authNotifier =
          container.read(authCtrlProvider.notifier) as _RecordingAuthCtrl;

      await container.read(tierReconcileCtrlProvider.notifier).reconcile();

      expect(authNotifier.refreshCalls, 1);
      expect(statusCalls, greaterThanOrEqualTo(1));
    },
  );

  test('non-eager reconcile debounces rapid re-runs', () async {
    final container = ProviderContainer(
      overrides: [
        authCtrlProvider.overrideWith(_RecordingAuthCtrl.new),
        subscriptionStatusProvider.overrideWith((ref) async => _proStatus),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    final authNotifier =
        container.read(authCtrlProvider.notifier) as _RecordingAuthCtrl;
    final notifier = container.read(tierReconcileCtrlProvider.notifier);

    await notifier.reconcile();
    await notifier.reconcile();

    expect(authNotifier.refreshCalls, 1);
  });

  test('markPurchasePending toggles hasPendingPurchase', () {
    final container = ProviderContainer(
      overrides: [
        authCtrlProvider.overrideWith(_RecordingAuthCtrl.new),
        subscriptionStatusProvider.overrideWith((ref) async => _proStatus),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(tierReconcileCtrlProvider.notifier);

    expect(notifier.hasPendingPurchase, isFalse);
    notifier.markPurchasePending();
    expect(notifier.hasPendingPurchase, isTrue);
  });

  test('eager reconcile polls until Pro and clears the pending flag', () async {
    var statusCalls = 0;
    final container = ProviderContainer(
      overrides: [
        authCtrlProvider.overrideWith(_RecordingAuthCtrl.new),
        subscriptionStatusProvider.overrideWith((ref) async {
          statusCalls++;
          return statusCalls >= 2 ? _proStatus : _freeStatus;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    final authNotifier =
        container.read(authCtrlProvider.notifier) as _RecordingAuthCtrl;
    final notifier = container.read(tierReconcileCtrlProvider.notifier);

    notifier.markPurchasePending();
    await notifier.reconcile(eager: true);

    expect(container.read(currentTierProvider), SubscriptionTier.pro);
    expect(authNotifier.refreshCalls, greaterThanOrEqualTo(1));
    expect(notifier.hasPendingPurchase, isFalse);
  });
}
