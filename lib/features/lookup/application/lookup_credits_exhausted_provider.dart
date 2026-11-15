library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lookup_credits_exhausted_provider.g.dart';

enum LookupSectionId { translation, dictionary, contextualTranslation }

@riverpod
class LookupCreditsExhausted extends _$LookupCreditsExhausted {
  /// Last result token per section, for the wallet-refresh dedup: a rebuild
  /// that re-emits the same cached result or standing error refreshes
  /// nothing. Lives on the notifier, whose lifetime is the sheet's — a closed
  /// sheet drops its tokens with it.
  final Map<LookupSectionId, Object?> _lastTokenPerSection = {};

  @override
  Map<LookupSectionId, String> build() => const {};

  /// Whether [resultToken] is fresh for [section] and the wallet summary
  /// should be invalidated after this frame.
  bool markSummaryToken(LookupSectionId section, Object? resultToken) {
    if (resultToken == null) return true;
    if (identical(_lastTokenPerSection[section], resultToken)) return false;
    _lastTokenPerSection[section] = resultToken;
    return true;
  }

  void report(LookupSectionId section, String message) {
    if (state[section] == message) return;
    state = {...state, section: message};
  }

  void clear(LookupSectionId section) {
    if (!state.containsKey(section)) return;
    state = Map.of(state)..remove(section);
  }
}
