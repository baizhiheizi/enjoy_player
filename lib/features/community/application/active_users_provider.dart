/// Fetches community active learners when the user is signed in.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/api/services/user_api_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';

part 'active_users_provider.g.dart';

final Logger _activeUsersLog = logNamed('community');

@riverpod
Future<ActiveUsersResponse?> activeUsers(Ref ref) async {
  final authState = ref.watch(authCtrlProvider);
  final auth = authState.valueOrNull;
  if (auth is! AuthSignedIn) return null;

  final api = ref.watch(userApiProvider);
  final sw = Stopwatch()..start();
  _activeUsersLog.info('community: activeUsers request start');
  try {
    final json = await api.activeUsers(timezone: DateTime.now().timeZoneName);
    _activeUsersLog.info(
      'community: activeUsers done in ${sw.elapsedMilliseconds}ms',
    );
    return ActiveUsersResponse.fromJson(json);
  } catch (e, st) {
    _activeUsersLog.warning(
      'community: activeUsers failed after ${sw.elapsedMilliseconds}ms',
      e,
      st,
    );
    rethrow;
  }
}
