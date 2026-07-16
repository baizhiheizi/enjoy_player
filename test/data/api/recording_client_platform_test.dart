import 'dart:io' show Platform;

import 'package:enjoy_player/data/api/recording_client_platform.dart';
import 'package:enjoy_player/data/api/recording_client_platform_io.dart'
    hide recordingClientPlatformValue;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recordingClientPlatformValue dispatches to the IO implementation on this test host',
    () {
      // Every host that runs the Dart test command (linux, macOS, windows)
      // has dart:io, so the conditional import selects the IO file. We
      // only need to confirm the public surface delegates to it without
      // throwing.
      expect(recordingClientPlatformValue(), recordingClientPlatformIoValue());
    },
  );

  test('recordingClientPlatformIoValue is one of the supported platforms', () {
    const supported = <String>{'android', 'ios', 'macos', 'windows', 'linux'};
    expect(supported.contains(recordingClientPlatformIoValue()), isTrue);
  });

  test('recordingClientPlatformValue returns linux when Platform.isLinux', () {
    // When running on a Linux test host, the client_platform string must be
    // 'linux' so the backend classifies it correctly (ADR-0048, FR-020).
    if (!Platform.isLinux) {
      // The test host is not Linux, so we only verify the IO value is one
      // of the supported platforms (already covered above). This test
      // documents the contract: when the test runs on Linux, the value
      // IS 'linux'.
      return;
    }
    expect(recordingClientPlatformValue(), 'linux');
    expect(recordingClientPlatformIoValue(), 'linux');
  });
}
