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
    try {
      final result = await ref
          .read(dictionaryServiceProvider)
          .lookup(
            word: item.word,
            sourceLanguage: item.language,
            targetLanguage: item.targetLanguage,
          );
      final json = encodeDictionaryExplanation(result);
      final updated = await ref
          .read(vocabularyRepositoryProvider)
          .updateItemExplanation(itemId: item.id, explanation: json);
      if (updated == null) {
        state = state.copyWith(
          dictionaryFetchInFlight: false,
          dictionaryError: 'persist_failed',
        );
        return;
      }
      final queue = List<VocabularyItem>.from(state.queue);
      final idx = queue.indexWhere((i) => i.id == item.id);
      if (idx >= 0) queue[idx] = updated;
      state = state.copyWith(
        queue: queue,
        dictionaryFetchInFlight: false,
        clearDictionaryError: true,
      );
    } on CreditsFailure catch (failure, st) {
      _log.warning('Dictionary fetch rejected: credits', failure, st);
      state = state.copyWith(
        dictionaryFetchInFlight: false,
        dictionaryError: 'credits',
      );
    } catch (e, st) {
      _log.warning('Dictionary fetch failed', e, st);
      state = state.copyWith(
        dictionaryFetchInFlight: false,
        dictionaryError: 'fetch_failed',
      );
    }
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
    try {
      final result = await ref
          .read(contextualTranslationServiceProvider)
          .translate(
            text: ctx.text,
            sourceLanguage: item.language,
            targetLanguage: item.targetLanguage,
            context: item.word,
          );
      final json = encodeContextualExplanation(result);
      final updated = await ref
          .read(vocabularyRepositoryProvider)
          .updateContextExplanation(contextId: ctx.id, explanation: json);
      if (updated == null) {
        state = state.copyWith(
          contextualFetchInFlight: false,
          contextualError: 'persist_failed',
        );
        return;
      }
      final contexts = Map<String, List<VocabularyContext>>.from(
        state.contextsByItemId,
      );
      final list = List<VocabularyContext>.from(contexts[item.id] ?? const []);
      final i = list.indexWhere((c) => c.id == updated.id);
      if (i >= 0) {
        list[i] = updated;
      }
      contexts[item.id] = list;
      state = state.copyWith(
        contextsByItemId: contexts,
        contextualFetchInFlight: false,
        clearContextualError: true,
      );
    } on CreditsFailure catch (failure, st) {
      _log.warning('Contextual translation rejected: credits', failure, st);
      state = state.copyWith(
        contextualFetchInFlight: false,
        contextualError: 'credits',
      );
    } catch (e, st) {
      _log.warning('Contextual translation fetch failed', e, st);
      state = state.copyWith(
        contextualFetchInFlight: false,
        contextualError: 'fetch_failed',
      );
    }
  }
}
