/// Increments when [authCtrlProvider] changes so [GoRouter] re-runs redirects.
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';

part 'auth_router_tick.g.dart';

@Riverpod(keepAlive: true)
ValueNotifier<int> authRouterTick(Ref ref) {
  final vn = ValueNotifier(0);
  ref.onDispose(vn.dispose);
  ref.listen(authCtrlProvider, (previous, next) {
    vn.value++;
  });
  return vn;
}
