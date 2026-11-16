/// Fetches community active learners when the user is signed in.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/utils/client_timezone.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';

part 'active_users_provider.g.dart';

final Logger _activeUsersLog = logNamed('community');

@riverpod
Future<ActiveUsersResponse?> activeUsers(Ref ref) async {
  final signedInUserId = ref.watch(
    authCtrlProvider.select((a) {
      final v = a.valueOrNull;
      return v is AuthSignedIn ? v.profile.id : null;
    }),
  );
  if (signedInUserId == null) return null;

  final api = ref.watch(userApiProvider);
  final sw = Stopwatch()..start();
  _activeUsersLog.info('community: activeUsers request start');
  try {
    final json = await api
        .activeUsers(timezone: await clientTimezoneId())
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
