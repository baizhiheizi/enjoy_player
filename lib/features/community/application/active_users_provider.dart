/// Fetches community active learners when the user is signed in.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
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
    final json = await api
        .activeUsers(timezone: DateTime.now().timeZoneName)
        .timeout(const Duration(seconds: 8));
    _activeUsersLog.info(
      'community: activeUsers done in ${sw.elapsedMilliseconds}ms',
    );
    return ActiveUsersResponse.fromJson(json);
  } on TimeoutException catch (e, st) {
    _activeUsersLog.warning(
      'community: activeUsers timed out after ${sw.elapsedMilliseconds}ms',
      e,
      st,
    );
    return null;
  } catch (e, st) {
    _activeUsersLog.warning(
      'community: activeUsers failed after ${sw.elapsedMilliseconds}ms',
      e,
      st,
    );
    rethrow;
  }
}
