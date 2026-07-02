/// `GET /credits/usages` — authenticated Worker credits audit log.
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/query_params.dart';
import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_log.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_page.dart';

class CreditsApi extends RestApi {
  CreditsApi(super.client);

  static const _path = '/credits/usages';

  /// [limit] is clamped server-side to \[1, 100\]; default 50 matches Worker.
  Future<CreditsUsagePage> getUsages({
    String? startDate,
    String? endDate,
    String? serviceType,
    int limit = 50,
    int offset = 0,
  }) async {
    final map = await client.getJson(
      _path,
      queryParameters: buildQuery({
        'limit': limit,
        'offset': offset,
        'startDate': startDate,
        'endDate': endDate,
        'serviceType': serviceType,
      }),
    );
    final raw = map['logs'];
    final logs = <CreditsUsageLog>[];
    if (raw is List) {
      for (final e in raw) {
        final entry = castJsonObjectOrNull(e);
        if (entry != null) {
          logs.add(CreditsUsageLog.fromJson(entry));
        }
      }
    }

    return CreditsUsagePage(logs: logs, hasMore: logs.length >= limit);
  }
}
