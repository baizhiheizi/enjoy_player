import 'dart:io' show Platform;

/// Sent as `client_platform` on recording uploads (matches Enjoy native clients).
String recordingClientPlatformValue() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'windows';
}

/// Public alias used by tests to compare against the conditional-import
/// dispatch result without re-implementing the platform check.
String recordingClientPlatformIoValue() => recordingClientPlatformValue();
