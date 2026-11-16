import 'package:enjoy_player/core/routing/auth_router_tick.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAuthCtrl extends AuthCtrl {
  _TestAuthCtrl(this._initial);

  final AuthState _initial;

  @override
  Future<AuthState> build() async => _initial;

  void emitState(AsyncValue<AuthState> next) {
    state = next;
  }
}

void main() {
  const profile = UserProfile(
    id: 'user-1',
    email: 'test@example.com',
    name: 'Test',
  );

  test(
    'authRouterTick ignores profile-only updates when auth status is unchanged',
    () async {
      late _TestAuthCtrl authCtrl;
      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(() {
            authCtrl = _TestAuthCtrl(const AuthSignedIn(profile: profile));
            return authCtrl;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final tick = container.read(authRouterTickProvider);
      final baseline = tick.value;

      authCtrl.emitState(
        AsyncData(AuthSignedIn(profile: profile.copyWith(name: 'Updated'))),
      );
      expect(tick.value, baseline);

      authCtrl.emitState(const AsyncData(AuthSignedOut()));
      expect(tick.value, baseline + 1);

      authCtrl.emitState(const AsyncData(AuthSignedIn(profile: profile)));
      expect(tick.value, baseline + 2);
    },
  );
}
