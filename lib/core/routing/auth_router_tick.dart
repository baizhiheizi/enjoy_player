/// Increments when [authCtrlProvider] changes so [GoRouter] re-runs redirects.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';

part 'auth_router_tick.g.dart';

@Riverpod(keepAlive: true)
ValueNotifier<int> authRouterTick(Ref ref) {
  final vn = ValueNotifier(0);
  ref.onDispose(vn.dispose);
  ref.listen(
    authCtrlProvider.select(
      (a) => (a.isLoading, a.hasError, a.valueOrNull is AuthSignedIn),
    ),
    (previous, next) {
      vn.value++;
    },
  );
  return vn;
}
