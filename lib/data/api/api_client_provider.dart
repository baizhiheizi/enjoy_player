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
    // Worker routes (chat, ASR, translation, YouTube transcripts, …) live
    // on a separate origin from the public API, so with no persisted
    // override we always default to the worker origin. Following
    // [apiBaseUrl] here would let the no-override branch land on
    // `https://enjoy.bot`, which 404s on `/youtube/transcripts`.
    //
    // Users who actually want the AI URL to follow a non-default API URL
    // (e.g. a staging origin where worker + API share a host) can opt in
    // explicitly via the "Use API URL" button — that calls
    // [clearOverride], which makes the in-memory state follow
    // [apiBaseUrl] until the next override. See #83, #105, #120.
    final raw = await db.settingsDao.getValue(SettingsKeys.apiAiBaseUrl);
    return normalizeApiBaseUrl(
      raw ?? kDefaultAiApiBaseUrl,
      kDefaultAiApiBaseUrl,
    );
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
