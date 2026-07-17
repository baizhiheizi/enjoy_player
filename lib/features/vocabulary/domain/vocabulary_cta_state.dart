/// Lookup-sheet add-to-vocabulary control state.
library;

enum VocabularyCtaKind {
  /// Word not in book — offer create.
  notInBook,

  /// Word in book, locator is new — offer append context.
  addContext,

  /// Exact media locator already saved — offer remove whole item.
  alreadyInVocabulary,
}
