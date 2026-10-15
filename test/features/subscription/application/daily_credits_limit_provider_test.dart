import 'dart:async';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/daily_credits_limit_provider.dart';
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

const _proStatus = SubscriptionStatus(
  subscriptionActive: true,
  subscriptionTier: SubscriptionTier.pro,
);

ProviderContainer _container({
  UserProfile? signedInProfile,
  required Future<SubscriptionStatus> Function() status,
}) {
  final overrides = <Override>[
    signedInProfile == null
        ? authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new)
        : authCtrlProvider.overrideWith(
            () => _SignedInAuthCtrl(signedInProfile),
          ),
    subscriptionStatusProvider.overrideWith((ref) => status()),
  ];
  return ProviderContainer(overrides: overrides);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live status limit wins when resolved', () async {
    final container = _container(
      signedInProfile: _freeProfile,
      status: () async => _proStatus,
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);
    await container.read(subscriptionStatusProvider.future);
    expect(
      container.read(dailyCreditsLimitProvider),
      dailyCreditsLimitForTier(SubscriptionTier.pro),
    );
  });

  test(
    'falls back to the cached profile tier while status is loading',
    () async {
      final container = _container(
        signedInProfile: _freeProfile,
        status: () => Completer<SubscriptionStatus>().future,
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      expect(
        container.read(dailyCreditsLimitProvider),
        dailyCreditsLimitForTier(SubscriptionTier.free),
      );
    },
  );

  test(
    'signed out falls back to the free tier limit while status is loading',
    () async {
      final container = _container(
        status: () => Completer<SubscriptionStatus>().future,
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      expect(
        container.read(dailyCreditsLimitProvider),
        dailyCreditsLimitForTier(SubscriptionTier.free),
      );
    },
  );

  test(
    'a failed status fetch falls back to the cached profile tier limit',
    () async {
      final container = _container(
        signedInProfile: _freeProfile,
        status: () => Future.error(StateError('offline')),
      );
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);
      expect(
        container.read(dailyCreditsLimitProvider),
        dailyCreditsLimitForTier(SubscriptionTier.free),
      );
    },
  );
}
