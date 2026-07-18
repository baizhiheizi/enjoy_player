/// Ephemeral flashcard review session state for Vocabulary.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';

final _log = logNamed('VocabularyReviewSession');

/// One step in the session navigation history (for ← previous).
final class ReviewHistoryEntry {
  const ReviewHistoryEntry({required this.itemId, required this.wasRated});

  final String itemId;
  final bool wasRated;
}

/// Mutable UI state for an active review run.
final class ReviewSessionState {
  const ReviewSessionState({
    required this.queue,
    this.index = 0,
    this.flipped = false,
    this.ratingInFlight = false,
    this.dictionaryFetchInFlight = false,
    this.contextualFetchInFlight = false,
    this.clipPlayInFlight = false,
    this.dictionaryError,
    this.contextualError,
    this.mediaError,
    this.ratedStack = const [],
    this.history = const [],
    this.completed = false,
    this.primaryContextByItemId = const {},
  });

  final List<VocabularyItem> queue;
  final int index;
  final bool flipped;
  final bool ratingInFlight;
  final bool dictionaryFetchInFlight;
  final bool contextualFetchInFlight;
  final bool clipPlayInFlight;
  final String? dictionaryError;
  final String? contextualError;
  final String? mediaError;
  final List<String> ratedStack;
  final List<ReviewHistoryEntry> history;
  final bool completed;
  final Map<String, VocabularyContext> primaryContextByItemId;

  bool get hasActiveSession => queue.isNotEmpty;

  bool get canUndo => ratedStack.isNotEmpty && !ratingInFlight;

  VocabularyItem? get currentItem {
    if (completed || index < 0 || index >= queue.length) return null;
    return queue[index];
  }

  VocabularyContext? get currentPrimaryContext {
    final item = currentItem;
    if (item == null) return null;
    return primaryContextByItemId[item.id];
  }

  int get total => queue.length;

  int get displayCurrent => completed ? total : (index + 1).clamp(1, total);

  /// Cards left after the current one (0 when complete or on the last card).
  int get remaining => completed ? 0 : (total - displayCurrent).clamp(0, total);

  VocabularyContext? primaryContextFor(String itemId) =>
      primaryContextByItemId[itemId];

  ReviewSessionState copyWith({
    List<VocabularyItem>? queue,
    int? index,
    bool? flipped,
    bool? ratingInFlight,
    bool? dictionaryFetchInFlight,
    bool? contextualFetchInFlight,
    bool? clipPlayInFlight,
    String? dictionaryError,
    bool clearDictionaryError = false,
    String? contextualError,
    bool clearContextualError = false,
    String? mediaError,
    bool clearMediaError = false,
    List<String>? ratedStack,
    List<ReviewHistoryEntry>? history,
    bool? completed,
    Map<String, VocabularyContext>? primaryContextByItemId,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      flipped: flipped ?? this.flipped,
      ratingInFlight: ratingInFlight ?? this.ratingInFlight,
      dictionaryFetchInFlight:
          dictionaryFetchInFlight ?? this.dictionaryFetchInFlight,
      contextualFetchInFlight:
          contextualFetchInFlight ?? this.contextualFetchInFlight,
      clipPlayInFlight: clipPlayInFlight ?? this.clipPlayInFlight,
      dictionaryError: clearDictionaryError
          ? null
          : (dictionaryError ?? this.dictionaryError),
      contextualError: clearContextualError
          ? null
          : (contextualError ?? this.contextualError),
      mediaError: clearMediaError ? null : (mediaError ?? this.mediaError),
      ratedStack: ratedStack ?? this.ratedStack,
      history: history ?? this.history,
      completed: completed ?? this.completed,
      primaryContextByItemId:
          primaryContextByItemId ?? this.primaryContextByItemId,
    );
  }
}

final vocabularyReviewSessionProvider =
    NotifierProvider<VocabularyReviewSession, ReviewSessionState>(
      VocabularyReviewSession.new,
    );

class VocabularyReviewSession extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() => const ReviewSessionState(queue: []);

  /// Whether a review queue is currently loaded (safe to read outside [build]).
  bool get hasActiveSession => state.hasActiveSession;

  /// Start a session from [options] against current book items.
  ///
  /// Returns `false` when the built queue is empty (caller shows a message).
  Future<bool> start(ReviewSelectionOptions options, {DateTime? now}) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    final items = await repo.listAll();
    final queue = buildVocabularySessionQueue(
      items: items,
      options: options,
      now: now ?? DateTime.now(),
    );
    if (queue.isEmpty) {
      state = const ReviewSessionState(queue: []);
      return false;
    }

    final contexts = <String, VocabularyContext>{};
    for (final item in queue) {
      final list = await repo.getContextsForItem(item.id);
      if (list.isEmpty) continue;
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      contexts[item.id] = list.first;
    }

    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      primaryContextByItemId: contexts,
    );
    return true;
  }

  /// Restore a previously built non-empty queue (tests / deep links).
  void startWithQueue(
    List<VocabularyItem> queue, {
    Map<String, VocabularyContext> primaryContextByItemId = const {},
  }) {
    if (queue.isEmpty) {
      state = const ReviewSessionState(queue: []);
      return;
    }
    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      primaryContextByItemId: primaryContextByItemId,
    );
  }

  void clear() {
    state = const ReviewSessionState(queue: []);
  }

  void flip() {
    final item = state.currentItem;
    if (item == null || state.completed || state.ratingInFlight) return;
    state = state.copyWith(flipped: true);
  }

  void unflip() {
    final item = state.currentItem;
    if (item == null ||
        state.completed ||
        state.ratingInFlight ||
        !state.flipped) {
      return;
    }
    state = state.copyWith(flipped: false);
  }

  void toggleFlip() {
    if (state.flipped) {
      unflip();
    } else {
      flip();
    }
  }

  Future<void> rate(VocabularyRating rating) async {
    final item = state.currentItem;
    if (item == null ||
        !state.flipped ||
        state.ratingInFlight ||
        state.completed) {
      return;
    }

    state = state.copyWith(ratingInFlight: true);
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final updated = await repo.markReviewed(itemId: item.id, rating: rating);
      final queue = List<VocabularyItem>.from(state.queue);
      if (updated != null) {
        queue[state.index] = updated;
      }
      final ratedStack = [...state.ratedStack, item.id];
      final history = [
        ...state.history,
        ReviewHistoryEntry(itemId: item.id, wasRated: true),
      ];
      final nextIndex = state.index + 1;
      if (nextIndex >= queue.length) {
        state = state.copyWith(
          queue: queue,
          ratedStack: ratedStack,
          history: history,
          ratingInFlight: false,
          completed: true,
          flipped: false,
          index: queue.length,
        );
      } else {
        state = state.copyWith(
          queue: queue,
          index: nextIndex,
          flipped: false,
          ratingInFlight: false,
          ratedStack: ratedStack,
          history: history,
        );
      }
    } catch (_) {
      state = state.copyWith(ratingInFlight: false);
      rethrow;
    }
  }

  void skip() {
    final item = state.currentItem;
    if (item == null || state.ratingInFlight || state.completed) return;
    final history = [
      ...state.history,
      ReviewHistoryEntry(itemId: item.id, wasRated: false),
    ];
    final nextIndex = state.index + 1;
    if (nextIndex >= state.queue.length) {
      state = state.copyWith(
        history: history,
        completed: true,
        flipped: false,
        index: state.queue.length,
      );
    } else {
      state = state.copyWith(
        index: nextIndex,
        flipped: false,
        history: history,
      );
    }
  }

  Future<void> undo() async {
    if (!state.canUndo) return;
    final itemId = state.ratedStack.last;
    state = state.copyWith(ratingInFlight: true);
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final restored = await repo.undoLatestReview(itemId);
      final queue = List<VocabularyItem>.from(state.queue);
      final idx = queue.indexWhere((i) => i.id == itemId);
      if (restored != null && idx >= 0) {
        queue[idx] = restored;
      }
      final ratedStack = List<String>.from(state.ratedStack)..removeLast();
      final history = List<ReviewHistoryEntry>.from(state.history);
      while (history.isNotEmpty) {
        final last = history.removeLast();
        if (last.itemId == itemId && last.wasRated) break;
      }
      final restoreIndex = idx >= 0 ? idx : state.index;
      state = state.copyWith(
        queue: queue,
        index: restoreIndex,
        flipped: false,
        ratingInFlight: false,
        ratedStack: ratedStack,
        history: history,
        completed: false,
      );
    } catch (_) {
      state = state.copyWith(ratingInFlight: false);
      rethrow;
    }
  }

  void previous() {
    if (state.history.isEmpty || state.ratingInFlight) return;
    final history = List<ReviewHistoryEntry>.from(state.history);
    final last = history.removeLast();
    final idx = state.queue.indexWhere((i) => i.id == last.itemId);
    if (idx < 0) {
      state = state.copyWith(history: history);
      return;
    }
    state = state.copyWith(
      history: history,
      index: idx,
      flipped: false,
      completed: false,
    );
  }

  Future<void> fetchDictionary() async {
    final item = state.currentItem;
    if (item == null || state.dictionaryFetchInFlight || state.completed) {
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
        state.completed) {
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
      final map = Map<String, VocabularyContext>.from(
        state.primaryContextByItemId,
      );
      map[item.id] = updated;
      state = state.copyWith(
        primaryContextByItemId: map,
        contextualFetchInFlight: false,
        clearContextualError: true,
      );
    } catch (e, st) {
      _log.warning('Contextual translation fetch failed', e, st);
      state = state.copyWith(
        contextualFetchInFlight: false,
        contextualError: 'fetch_failed',
      );
    }
  }

  Future<void> playClip() async {
    final ctx = state.currentPrimaryContext;
    if (ctx == null ||
        state.clipPlayInFlight ||
        state.completed ||
        !vocabularyContextSupportsMediaActions(ctx)) {
      return;
    }
    state = state.copyWith(clipPlayInFlight: true, clearMediaError: true);
    try {
      await playVocabularyClip(
        player: ref.read(playerControllerProvider.notifier),
        echo: ref.read(echoModeProvider.notifier),
        context: ctx,
      );
      state = state.copyWith(clipPlayInFlight: false);
    } catch (e, st) {
      _log.warning('Clip play failed', e, st);
      state = state.copyWith(
        clipPlayInFlight: false,
        mediaError: 'play_failed',
      );
    }
  }

  /// Clears the session and returns hand-off data after the user confirmed.
  ///
  /// Does not navigate or open media — the presentation layer does that.
  VocabularyMediaHandoff? takeMediaHandoff({required bool activateEcho}) {
    final ctx = state.currentPrimaryContext;
    if (ctx == null || !vocabularyContextSupportsMediaActions(ctx)) {
      return null;
    }
    final window = mediaLocatorWindow(ctx.locator!);
    final handoff = VocabularyMediaHandoff(
      mediaId: ctx.sourceId,
      startSec: window.startSec,
      endSec: window.endSec,
      activateEcho: activateEcho,
    );
    clear();
    return handoff;
  }
}
