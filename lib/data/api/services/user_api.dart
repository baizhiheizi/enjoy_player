/// `/api/v1/users/active` (active learners + optional community today stats).
library;

import 'package:enjoy_player/data/api/api_client.dart';

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  static const _path = '/api/v1/users/active';

  Future<Map<String, dynamic>> activeUsers({String? timezone}) {
    final q = timezone == null || timezone.isEmpty
        ? null
        : <String, String>{'timezone': timezone};
    return _client.getJson(_path, queryParameters: q);
  }
}
