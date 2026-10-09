library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lookup_credits_exhausted_provider.g.dart';

enum LookupSectionId { translation, dictionary, contextualTranslation }

@riverpod
class LookupCreditsExhausted extends _$LookupCreditsExhausted {
  @override
  Map<LookupSectionId, String> build() => const {};

  void report(LookupSectionId section, String message) {
    if (state[section] == message) return;
    state = {...state, section: message};
  }

  void clear(LookupSectionId section) {
    if (!state.containsKey(section)) return;
    state = Map.of(state)..remove(section);
  }

  void clearAll() {
    if (state.isEmpty) return;
    state = const {};
  }
}
