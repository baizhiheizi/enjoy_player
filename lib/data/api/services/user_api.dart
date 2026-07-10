/// `/api/v1/users/active` (active learners + optional community today stats).
library;

import 'package:enjoy_player/data/api/query_params.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

class UserApi extends RestApi {
  UserApi(super.client);

  static const _path = '/api/v1/users/active';

  Future<Map<String, dynamic>> activeUsers({String? timezone}) {
    return client.getJson(
      _path,
      queryParameters: buildQuery({'timezone': timezone}),
    );
  }
}
