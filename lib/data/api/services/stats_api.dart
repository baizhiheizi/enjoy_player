/// `/api/v1/mine/stats` (today/week/month learning statistics).
library;

import 'package:enjoy_player/data/api/rest_api.dart';

class StatsApi extends RestApi {
  StatsApi(super.client);

  static const _path = '/api/v1/mine/stats';

  Future<Map<String, dynamic>> learningStatistics({String? timezone}) {
    final q = timezone == null || timezone.isEmpty
        ? null
        : <String, String>{'timezone': timezone};
    return client.getJson(_path, queryParameters: q);
  }
}
