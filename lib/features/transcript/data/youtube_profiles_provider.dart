/// Lazily fetched YouTube InnerTube client profiles with `L1Store` cache.
///
/// The worker exposes `GET /youtube/client-profiles` returning a list of
/// {`name`, `version`, `client_name_header`, `user_agent`, `context`} entries
/// (snake_case on the wire; camelCase after [ApiClient] decode). We fetch
/// them once per session (TTL = 24 h) and fall back to the compile-time
/// [kBuiltInClientProfiles] when the worker is unreachable or returns an
/// empty / malformed list.
///
/// This is the runtime form of spec 013's FR-003: client profiles should
/// be remotely configurable, not hard-coded in the app binary.
library;

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/cache/lru_store.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/ai/ai_api_providers.dart';

import 'client_profile.dart';

part 'youtube_profiles_provider.g.dart';

final Logger _log = logNamed('YoutubeProfiles');

/// Cache key for [youtubeProfilesProvider]. Single shared entry — we only
/// need the latest list, not per-key lookups.
const String _kCacheKey = 'worker-profiles';

/// 24 h TTL — the worker's profile list moves slowly (only on a YouTube
/// client-version bump). The cache size is 1 (only the single key) so the
/// store never holds stale-but-unevicted data.
final L1Store<String, List<ClientProfile>> _profileCache =
    L1Store<String, List<ClientProfile>>(
      capacity: 1,
      ttl: const Duration(hours: 24),
    );

@Riverpod(keepAlive: true)
Future<List<ClientProfile>> youtubeProfiles(Ref ref) async {
  final cached = _profileCache.peek(_kCacheKey);
  if (cached != null) return cached;

  final client = ref.watch(youtubeTranscriptsClientProvider);
  try {
    final raw = await client.fetchClientProfiles();
    final profiles = clientProfilesFromJson(raw);
    if (profiles.isEmpty) {
      _log.fine('worker returned no usable profiles; using built-in defaults');
      return kBuiltInClientProfiles;
    }
    _profileCache.put(_kCacheKey, profiles);
    _log.info('loaded ${profiles.length} YouTube profile(s) from worker');
    return profiles;
  } on Object catch (e, st) {
    _log.warning('worker profile fetch failed; using built-in defaults', e, st);
    return kBuiltInClientProfiles;
  }
}
