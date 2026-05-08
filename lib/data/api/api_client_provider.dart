/// HTTP client + API base URL (same unit to avoid circular imports).
library;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'api_client_provider.g.dart';

@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
}

@Riverpod(keepAlive: true)
class ApiBaseUrl extends _$ApiBaseUrl {
  @override
  Future<String> build() async {
    final db = ref.watch(appDatabaseProvider);
    final raw = await db.settingsDao.getValue(SettingsKeys.apiBaseUrl);
    return _normalize(raw ?? kDefaultApiBaseUrl);
  }

  /// Persists and refreshes [apiClientProvider].
  Future<void> setBaseUrl(String input) async {
    final normalized = _normalize(input);
    await ref.read(appDatabaseProvider).settingsDao.setValue(
          SettingsKeys.apiBaseUrl,
          normalized,
        );
    state = AsyncData(normalized);
    ref.invalidate(apiClientProvider);
  }

  static String _normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      s = kDefaultApiBaseUrl;
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    return s;
  }
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final httpClient = ref.watch(httpClientProvider);
  final tokens = ref.watch(secureTokenStoreProvider);
  return ApiClient(
    httpClient: httpClient,
    getBaseUrl: () => ref.read(apiBaseUrlProvider.future),
    getAccessToken: tokens.readAccessToken,
  );
}
