/// Fetches community active learners when the user is signed in.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/services/user_api_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';

part 'active_users_provider.g.dart';

@riverpod
Future<ActiveUsersResponse?> activeUsers(Ref ref) async {
  final auth = await ref.watch(authCtrlProvider.future);
  if (auth is! AuthSignedIn) return null;

  final api = ref.watch(userApiProvider);
  final json = await api.activeUsers(timezone: DateTime.now().timeZoneName);
  return ActiveUsersResponse.fromJson(json);
}
