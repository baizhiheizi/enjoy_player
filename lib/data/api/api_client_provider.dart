/// HTTP client + API base URL (same unit to avoid circular imports).
library;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';

part 'api_client_provider.g.dart';

/// Normalizes a user-entered origin; [defaultWhenEmpty] is used when [raw] is blank.
String normalizeApiBaseUrl(String raw, String defaultWhenEmpty) {
  var s = raw.trim();
  if (s.isEmpty) {
    s = defaultWhenEmpty;
  }
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  if (!s.startsWith('http://') && !s.startsWith('https://')) {
    s = 'https://$s';
  }
  return s;
}

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
    final db = ref.watch(guestAppDatabaseProvider);
    final raw = await db.settingsDao.getValue(SettingsKeys.apiBaseUrl);
    return normalizeApiBaseUrl(raw ?? kDefaultApiBaseUrl, kDefaultApiBaseUrl);
  }

  /// Persists and refreshes [apiClientProvider].
  Future<void> setBaseUrl(String input) async {
    final normalized = normalizeApiBaseUrl(input, kDefaultApiBaseUrl);
    await ref
        .read(guestAppDatabaseProvider)
        .settingsDao
        .setValue(SettingsKeys.apiBaseUrl, normalized);
    state = AsyncData(normalized);
    ref.invalidate(apiClientProvider);
  }
}

@Riverpod(keepAlive: true)
class AiApiBaseUrl extends _$AiApiBaseUrl {
  @override
  Future<String> build() async {
    final db = ref.watch(guestAppDatabaseProvider);
    // When no AI base URL is explicitly persisted, follow the main
    // [ApiBaseUrl] (the worker lives on the same origin as the public
    // API by default). This keeps the two settings coupled by default
    // and avoids the "I changed the API URL but the AI still hits the
    // old host" footgun called out in #83. An explicit override in
    // settingsKv still wins.
    final raw = await db.settingsDao.getValue(SettingsKeys.apiAiBaseUrl);
    if (raw == null) {
      return ref.watch(apiBaseUrlProvider.future);
    }
    return normalizeApiBaseUrl(raw, await ref.read(apiBaseUrlProvider.future));
  }

  /// Persists and refreshes [aiApiClientProvider].
  Future<void> setBaseUrl(String input) async {
    final normalized = normalizeApiBaseUrl(input, kDefaultAiApiBaseUrl);
    await ref
        .read(guestAppDatabaseProvider)
        .settingsDao
        .setValue(SettingsKeys.apiAiBaseUrl, normalized);
    state = AsyncData(normalized);
    ref.invalidate(aiApiClientProvider);
  }

  /// Clears the override and falls back to following [apiBaseUrlProvider].
  Future<void> clearOverride() async {
    final db = ref.read(guestAppDatabaseProvider);
    await db.settingsDao.deleteValue(SettingsKeys.apiAiBaseUrl);
    state = AsyncData(await ref.read(apiBaseUrlProvider.future));
    ref.invalidate(aiApiClientProvider);
  }
}

@Riverpod(keepAlive: true)
ApiClient authApiClient(Ref ref) {
  final httpClient = ref.watch(httpClientProvider);
  final tokens = ref.watch(secureTokenStoreProvider);
  return ApiClient(
    httpClient: httpClient,
    getBaseUrl: () => ref.read(apiBaseUrlProvider.future),
    getAccessToken: tokens.readAccessToken,
  );
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final httpClient = ref.watch(httpClientProvider);
  final tokens = ref.watch(secureTokenStoreProvider);
  return ApiClient(
    httpClient: httpClient,
    getBaseUrl: () => ref.read(apiBaseUrlProvider.future),
    getAccessToken: tokens.readAccessToken,
    refreshAccessToken: () => ref.read(authRepositoryProvider).refreshSession(),
  );
}

@Riverpod(keepAlive: true)
ApiClient aiApiClient(Ref ref) {
  final httpClient = ref.watch(httpClientProvider);
  final tokens = ref.watch(secureTokenStoreProvider);
  return ApiClient(
    httpClient: httpClient,
    getBaseUrl: () => ref.read(aiApiBaseUrlProvider.future),
    getAccessToken: tokens.readAccessToken,
  );
}
