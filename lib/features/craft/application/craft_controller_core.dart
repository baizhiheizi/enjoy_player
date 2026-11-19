/// Shared core of the Craft controller stages: the preference-hydration
/// latch plus the language, voice, and TTS-failure helpers every stage reuses.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
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

  /// Runs one Craft AI call and maps its failure modes in a single place.
  ///
  /// [logLabel] names the logger and [surface] names the operation in the
  /// warning text, so each caller keeps its own log wording. [call] performs
  /// the request, [onSuccess] patches the state after a successful call, and
  /// [genericFailure] builds the failure for a non-credits error.
  /// [clearTranslating] and [clearTranscribing] name the busy flags the
  /// failure arms reset.
  ///
  /// Returns the call result, or null when the call failed.
  @protected
  Future<T?> runCraftAiCall<T>({
    required String logLabel,
    required String surface,
    required Future<T> Function() call,
    required CraftFailure Function() genericFailure,
    CraftJobState Function(T result)? onSuccess,
    bool clearTranslating = true,
    bool clearTranscribing = false,
  }) async {
    try {
      final result = await call();
      final patched = onSuccess?.call(result);
      if (patched != null) state = patched;
      return result;
    } on CreditsFailure catch (failure, st) {
      logNamed(logLabel).warning('$surface rejected: credits', failure, st);
      state = state.copyWith(
        isTranslating: clearTranslating ? false : null,
        isTranscribing: clearTranscribing ? false : null,
        failure: CraftCreditsFailure(failure),
      );
      return null;
    } catch (e, st) {
      logNamed(logLabel).warning('$surface failed: $e', e, st);
      state = state.copyWith(
        isTranslating: clearTranslating ? false : null,
        isTranscribing: clearTranscribing ? false : null,
        failure: genericFailure(),
      );
      return null;
    }
  }
}
