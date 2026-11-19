part of 'vocabulary_review_session.dart';

/// Async lookups: dictionary + contextual translation.
mixin VocabularyReviewSessionFetches on VocabularyReviewSessionBase {
  Future<void> fetchDictionary() async {
    final item = state.currentItem;
    if (item == null ||
        state.dictionaryFetchInFlight ||
        state.completed ||
        state.practiceSheetOpen) {
      return;
    }
    state = state.copyWith(
      dictionaryFetchInFlight: true,
      clearDictionaryError: true,
    );
    await _runAiFetch(
      creditsSurface: 'Dictionary fetch',
      failureSurface: 'Dictionary fetch',
      call: () => ref
          .read(dictionaryServiceProvider)
          .lookup(
            word: item.word,
            sourceLanguage: item.language,
            targetLanguage: item.targetLanguage,
          ),
      encode: encodeDictionaryExplanation,
      persist: (json) => ref
          .read(vocabularyRepositoryProvider)
          .updateItemExplanation(itemId: item.id, explanation: json),
      onPersisted: (updated) {
        final queue = List<VocabularyItem>.from(state.queue);
        final idx = queue.indexWhere((i) => i.id == item.id);
        if (idx >= 0) queue[idx] = updated;
        return state.copyWith(
          queue: queue,
          dictionaryFetchInFlight: false,
          clearDictionaryError: true,
        );
      },
      onError: (error) => state.copyWith(
        dictionaryFetchInFlight: false,
        dictionaryError: error,
      ),
    );
  }

  Future<void> fetchContextualTranslation() async {
    final item = state.currentItem;
    final ctx = state.currentPrimaryContext;
    if (item == null ||
        ctx == null ||
        state.contextualFetchInFlight ||
        state.completed ||
        state.practiceSheetOpen) {
      return;
    }
    state = state.copyWith(
      contextualFetchInFlight: true,
      clearContextualError: true,
    );
    await _runAiFetch(
      creditsSurface: 'Contextual translation',
      failureSurface: 'Contextual translation fetch',
      call: () => ref
          .read(contextualTranslationServiceProvider)
          .translate(
            text: ctx.text,
            sourceLanguage: item.language,
            targetLanguage: item.targetLanguage,
            context: item.word,
          ),
      encode: encodeContextualExplanation,
      persist: (json) => ref
          .read(vocabularyRepositoryProvider)
          .updateContextExplanation(contextId: ctx.id, explanation: json),
      onPersisted: (updated) {
        final contexts = Map<String, List<VocabularyContext>>.from(
          state.contextsByItemId,
        );
        final list = List<VocabularyContext>.from(
          contexts[item.id] ?? const [],
        );
        final i = list.indexWhere((c) => c.id == updated.id);
        if (i >= 0) {
          list[i] = updated;
        }
        contexts[item.id] = list;
        return state.copyWith(
          contextsByItemId: contexts,
          contextualFetchInFlight: false,
          clearContextualError: true,
        );
      },
      onError: (error) => state.copyWith(
        contextualFetchInFlight: false,
        contextualError: error,
      ),
    );
  }

  Future<void> _runAiFetch<T, P extends Object>({
    required String creditsSurface,
    required String failureSurface,
    required Future<T> Function() call,
    required String Function(T result) encode,
    required Future<P?> Function(String json) persist,
    required ReviewSessionState Function(P persisted) onPersisted,
    required ReviewSessionState Function(String error) onError,
  }) async {
    try {
      final result = await call();
      final json = encode(result);
      final persisted = await persist(json);
      if (persisted == null) {
        state = onError(kVocabularyAiErrorPersistFailed);
        return;
      }
      state = onPersisted(persisted);
    } on CreditsFailure catch (failure, st) {
      _log.warning('$creditsSurface rejected: credits', failure, st);
      state = onError(kVocabularyAiErrorCredits);
    } catch (e, st) {
      _log.warning('$failureSurface failed', e, st);
      state = onError(kVocabularyAiErrorFetchFailed);
    }
  }
}
