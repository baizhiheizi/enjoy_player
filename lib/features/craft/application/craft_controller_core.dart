/// Shared core of the Craft controller stages: the preference-hydration
/// latch plus the language, voice, and TTS-failure helpers every stage reuses.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/craft/application/craft_preferences_provider.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';

/// Hydration latch and the shared language / voice helpers every Craft
/// stage mixin builds on.
mixin CraftControllerCore on Notifier<CraftJobState> {
  /// Set by every user-intent setter so a late preference hydration never
  /// clobbers choices the user already made this session.
  @protected
  bool prefsHydrationMutated = false;

  @protected
  String baseLanguage(String tag) => tag.split('-').first.toLowerCase();

  @protected
  bool sameBaseLanguage(String a, String b) =>
      baseLanguage(a) == baseLanguage(b);

  /// Keep [current] when it belongs to [language]; otherwise fall back to
  /// the remembered voice for that language, then the catalog default.
  @protected
  String? voiceMatchingLanguage(String language, String? current) {
    final base = baseLanguage(language);
    final voices = voicesForLanguage(base);
    if (current != null && voices.any((v) => v.id == current)) {
      return current;
    }
    final remembered = ref.read(craftPreferencesCtrlProvider).voices[base];
    if (remembered != null && voices.any((v) => v.id == remembered)) {
      return remembered;
    }
    return defaultVoiceForLanguage(base)?.id;
  }

  @protected
  CraftFailure mapTtsFailure(Object error) {
    if (error is CreditsFailure) {
      return CraftCreditsFailure(error);
    }
    if (error is ByokNotConfiguredFailure) {
      return const CraftTtsFailure(action: CraftFailureAction.openAiSettings);
    }
    if (error is ApiException && error.statusCode == 401) {
      return const CraftTtsFailure(action: CraftFailureAction.openAiSettings);
    }
    return const CraftTtsFailure();
  }
}
