/// Resolves `client_platform` for recording API payloads.
///
/// The conditional import selects the IO implementation on every platform
/// Enjoy Player targets (Android / iOS / macOS / Windows); the stub is
/// the unreachable non-IO fallback that Dart requires for the conditional
/// import to compile, and it deliberately throws so we never silently
/// label a recording as `'web'` (AGENTS.md forbids Flutter web).
library;

import 'recording_client_platform_stub.dart'
    if (dart.library.io) 'recording_client_platform_io.dart'
    as recording_platform;

/// Lowercase OS key for [RecordingApi.clientPlatform] (`windows`, `macos`, …).
String recordingClientPlatformValue() =>
    recording_platform.recordingClientPlatformValue();
