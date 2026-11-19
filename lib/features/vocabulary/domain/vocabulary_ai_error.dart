/// Error sentinels for the flashcard's AI-backed fetches.
library;

/// The request was rejected for insufficient credits.
const kVocabularyAiErrorCredits = 'credits';

/// The request failed for a reason other than credits.
const kVocabularyAiErrorFetchFailed = 'fetch_failed';

/// The fetched result could not be persisted.
const kVocabularyAiErrorPersistFailed = 'persist_failed';
