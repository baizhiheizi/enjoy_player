import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/credits_api.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_log.dart';

void main() {
  test('CreditsApi.getUsages builds query and parses logs', () async {
    http.Request? captured;
    final mock = MockClient((request) async {
      captured = request;
      return http.Response(
        '''
        {
          "logs": [
            {
              "id": "log-1",
              "userId": "u1",
              "date": "2024-01-15",
              "timestamp": 1705276800000,
              "serviceType": "llm",
              "tier": "pro",
              "required": 10,
              "usedBefore": 100,
              "usedAfter": 110,
              "allowed": true,
              "meta": {"model": "x"}
            }
          ]
        }
        ''',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = CreditsApi(
      ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://worker.example.com',
        getAccessToken: () async => 'tok',
      ),
    );

    final page = await api.getUsages(
      startDate: '2024-01-01',
      endDate: '2024-01-31',
      serviceType: 'llm',
      limit: 50,
      offset: 10,
    );

    expect(captured, isNotNull);
    final uri = captured!.url;
    expect(uri.path, '/api/v1/credits/usages');
    expect(uri.queryParameters['start_date'], '2024-01-01');
    expect(uri.queryParameters['end_date'], '2024-01-31');
    expect(uri.queryParameters['service_type'], 'llm');
    expect(uri.queryParameters['limit'], '50');
    expect(uri.queryParameters['offset'], '10');

    expect(page.logs, hasLength(1));
    final log = page.logs.single;
    expect(log.id, 'log-1');
    expect(log.userId, 'u1');
    expect(log.date, '2024-01-15');
    expect(log.timestampMs, 1705276800000);
    expect(log.serviceType, 'llm');
    expect(log.tier, 'pro');
    expect(log.creditsRequired, 10);
    expect(log.usedBefore, 100);
    expect(log.usedAfter, 110);
    expect(log.allowed, isTrue);
    expect(log.meta, isNotNull);
    expect(log.meta!['model'], 'x');

    expect(page.hasMore, isFalse);
  });

  test('CreditsUsageLog.fromJson maps required key to creditsRequired', () {
    final log = CreditsUsageLog.fromJson({
      'id': 'a',
      'userId': 'b',
      'date': '2024-02-01',
      'timestamp': 1,
      'serviceType': 'tts',
      'tier': 'free',
      'required': 3,
      'usedBefore': 0,
      'usedAfter': 3,
      'allowed': 0,
    });
    expect(log.creditsRequired, 3);
    expect(log.allowed, isFalse);
  });
}
