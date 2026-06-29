/// Web / non-IO fallback. EnjoyPlayer only ships on Android, iOS, macOS,
/// and Windows (`if (dart.library.io)` conditional import in
/// `recording_client_platform.dart` always picks the IO variant on those
/// targets). If this stub is ever reached, the app is running on a target
/// the rest of the code does not support (Linux? Web?) and the upload
/// client platform string is intentionally undefined rather than a
/// misleading `'web'` default.
String recordingClientPlatformValue() => throw UnsupportedError(
  'recordingClientPlatformValue: no platform-specific implementation '
  'was selected by the conditional import. Enjoy Player targets '
  'Android, iOS, macOS, and Windows only.',
);
