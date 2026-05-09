/// Riverpod wiring for [UserApi].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/services/user_api.dart';

part 'user_api_provider.g.dart';

@Riverpod(keepAlive: true)
UserApi userApi(Ref ref) {
  return UserApi(ref.watch(apiClientProvider));
}
