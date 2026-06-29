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

/// Picked file is not an allowed local audio/video type (e.g. image or document).
final class UnsupportedImportFileFailure extends AppFailure {
  const UnsupportedImportFileFailure() : super('');
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

/// Categorizes auth failures so the UI can render distinct messages
/// (e.g. "invalid credentials" vs "rate limited" vs "network down") and
/// the auth repository can decide whether to keep the existing session.
enum AuthFailureCode {
  /// User supplied bad credentials (bad OTP, bad email, expired PKCE).
  invalidCredentials,

  /// The server explicitly rejected the session (HTTP 401 or 403). The
  /// refresh-token grant is no longer valid; the local session should
  /// be cleared.
  sessionRevoked,

  /// The server asked the caller to slow down (HTTP 429).
  rateLimited,

  /// The request never reached the server, or the server did not respond
  /// in time. The local session is presumed still valid and must be kept
  /// so the next call can retry.
  networkUnreachable,

  /// The server returned a 5xx that the client cannot classify further.
  /// The local session is presumed still valid; retry later.
  serverError,

  /// Catch-all for unclassified auth errors.
  unknown,
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {this.code = AuthFailureCode.unknown});

  final AuthFailureCode code;

  bool get isSessionRevoked => code == AuthFailureCode.sessionRevoked;
}

/// Worker returned HTTP 402 (AI credits exhausted or billing block).
final class CreditsFailure extends AppFailure {
  const CreditsFailure(super.message);
}
