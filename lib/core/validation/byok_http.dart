/// BYOK HTTP policy helpers co-located with the URL guard so the
/// "is the URL allowed + how do we normalize it" pair lives together.
///
/// `byok_llm_model_factory.dart` historically owned [normalizeByokBaseUrl];
/// it lives here now that the Whisper / speech / model-fetch HTTP clients
/// also need it (see `lib/features/ai/data/byok/byok_http_client.dart`).
library;

export 'package:enjoy_player/core/validation/byok_url_guard.dart'
    show isByokBaseUrlAllowed;

/// Strip trailing `/` characters from a BYOK base URL.
String normalizeByokBaseUrl(String raw) {
  var url = raw.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}
