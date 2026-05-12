/// Thrown when native Azure Speech operations fail or return no usable payload.
final class AzureSpeechException implements Exception {
  const AzureSpeechException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Machine-readable: `no_speech`, `canceled`, `parse_error`, `platform_error`, etc.
  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'AzureSpeechException($code): $message';
}
