import 'dart:async';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  _SignedInAuthCtrl(this.profile);
  final UserProfile profile;
  @override
  Future<AuthState> build() async => AuthSignedIn(profile: profile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

const _freeProfile = UserProfile(
  id: 'u1',
  email: 'a@b.com',
  name: 'Free',
  subscriptionTier: SubscriptionTier.free,
);
const _proProfile = UserProfile(
  id: 'u1',
  email: 'a@b.com',
  name: 'Pro',
  subscriptionTier: SubscriptionTier.pro,
);
const _proStatus = SubscriptionStatus(
  subscriptionActive: true,
  subscriptionTier: SubscriptionTier.pro,
);
const _freeStatus = SubscriptionStatus(
  subscriptionActive: true,
  subscriptionTier: SubscriptionTier.free,
);

ProviderContainer _container({
  UserProfile? signedInProfile,
  Future<SubscriptionStatus> Function()? status,
}) {
  final overrides = <Override>[
    signedInProfile == null
        ? authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new)
        : authCtrlProvider.overrideWith(
            () => _SignedInAuthCtrl(signedInProfile),
          ),
    subscriptionStatusProvider.overrideWith((ref) => status!()),
  ];
  return ProviderContainer(overrides: overrides);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed out resolves to free', () async {
    final container = _container(status: () async => _proStatus);
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    expect(container.read(currentTierProvider), SubscriptionTier.free);
  });

  test(
    'signed in, status loading falls back to cached profile tier (pro)',
    () async {
      final container = _container(
        signedInProfile: _proProfile,
        status: () => Completer<SubscriptionStatus>().future,
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      // Status never completes (loading) → cached profile tier wins.
      expect(container.read(currentTierProvider), SubscriptionTier.pro);
    },
  );

  test(
    'signed in, status loading falls back to cached profile tier (free)',
    () async {
      final container = _container(
        signedInProfile: _freeProfile,
        status: () => Completer<SubscriptionStatus>().future,
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      expect(container.read(currentTierProvider), SubscriptionTier.free);
    },
  );

  test('live status pro wins over cached free profile', () async {
    final container = _container(
      signedInProfile: _freeProfile,
      status: () async => _proStatus,
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    await container.read(subscriptionStatusProvider.future);
    expect(container.read(currentTierProvider), SubscriptionTier.pro);
  });

  test('live status free matches cached free profile', () async {
    final container = _container(
      signedInProfile: _freeProfile,
      status: () async => _freeStatus,
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    await container.read(subscriptionStatusProvider.future);
    expect(container.read(currentTierProvider), SubscriptionTier.free);
  });
}
