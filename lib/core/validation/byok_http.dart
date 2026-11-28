/// BYOK HTTP policy helpers co-located with the URL guard so the
/// "is the URL allowed + how do we normalize it" pair lives together.
///
/// `byok_llm_model_factory.dart` historically owned [normalizeByokBaseUrl];
/// it lives here now that the Whisper / speech / model-fetch HTTP clients
/// also need it (see `lib/features/ai/data/byok/byok_http_client.dart`).
library;

import 'package:enjoy_player/core/validation/trim_trailing_slashes.dart';

export 'package:enjoy_player/core/validation/byok_url_guard.dart'
    show isByokBaseUrlAllowed;

/// Strip trailing `/` characters from a BYOK base URL.
String normalizeByokBaseUrl(String raw) => trimTrailingSlashes(raw.trim());
