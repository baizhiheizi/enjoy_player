/// Typed failures for UI and repositories.
library;

sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class FileFailure extends AppFailure {
  const FileFailure(super.message);
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

final class PlaybackFailure extends AppFailure {
  const PlaybackFailure(super.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {this.statusCode});

  final int? statusCode;
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// Worker returned HTTP 402 (AI credits exhausted or billing block).
final class CreditsFailure extends AppFailure {
  const CreditsFailure(super.message);
}
