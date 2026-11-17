/// State bundles of the vocabulary flashcard.
///
/// The flashcard threads three groups of values through its front / back /
/// context-tab layers: the in-flight flags and error strings of its
/// AI-backed surfaces, the context pager position, and the callbacks the
/// surfaces trigger. Bundling them keeps the wiring in one place — the
/// session screen builds each bundle once — so a new flashcard action or
/// fetch state reaches every layer through one object.
library;

import 'package:flutter/foundation.dart';

/// In-flight flags and error strings of the flashcard's AI-backed surfaces.
class FlashcardFetchState {
  const FlashcardFetchState({
    this.dictionaryFetchInFlight = false,
    this.contextualFetchInFlight = false,
    this.clipPlayInFlight = false,
    this.dictionaryError,
    this.contextualError,
    this.mediaError,
  });

  final bool dictionaryFetchInFlight;
  final bool contextualFetchInFlight;
  final bool clipPlayInFlight;
  final String? dictionaryError;
  final String? contextualError;
  final String? mediaError;
}

/// Context pager position of the flashcard.
class FlashcardContextState {
  const FlashcardContextState({this.count = 0, this.index = 0});

  final int count;
  final int index;

  bool get hasMultiple => count > 1;
}

/// Callbacks the flashcard surfaces trigger, plus the gate that disables them
/// while a modal surface owns the input.
class FlashcardActions {
  const FlashcardActions({
    required this.onFlip,
    required this.onUnflip,
    required this.onFetchDictionary,
    required this.onFetchContextual,
    required this.onPlayClip,
    required this.onOpenInPlayer,
    required this.onShadowReading,
    this.onPreviousContext,
    this.onNextContext,
    this.enabled = true,
  });

  final VoidCallback onFlip;
  final VoidCallback onUnflip;
  final VoidCallback onFetchDictionary;
  final VoidCallback onFetchContextual;
  final VoidCallback onPlayClip;
  final VoidCallback onOpenInPlayer;
  final VoidCallback onShadowReading;
  final VoidCallback? onPreviousContext;
  final VoidCallback? onNextContext;
  final bool enabled;
}
