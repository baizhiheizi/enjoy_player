/// Terminal or transport failure for an Enjoy long-form transcription job.
library;

final class AsrLongFormJobException implements Exception {
  const AsrLongFormJobException({
    required this.category,
    required this.retryable,
    this.message,
  });

  final String category;
  final bool retryable;
  final String? message;

  @override
  String toString() =>
      'AsrLongFormJobException($category, retryable=$retryable)';
}
