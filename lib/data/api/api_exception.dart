/// HTTP / transport failures from [ApiClient].
library;

final class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final Object? body;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() =>
      'ApiException($statusCode): $message${body != null ? ' body=$body' : ''}';
}
