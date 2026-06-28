import 'package:enjoy_player/data/api/recording_client_platform.dart';
import 'package:enjoy_player/data/api/recording_client_platform_io.dart'
    hide recordingClientPlatformValue;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recordingClientPlatformValue dispatches to the IO implementation on this test host', () {
    // Every host that runs the Dart test command (linux, macOS, windows)
    // has dart:io, so the conditional import selects the IO file. We
    // only need to confirm the public surface delegates to it without
    // throwing.
    expect(
      recordingClientPlatformValue(),
      recordingClientPlatformIoValue(),
    );
  });

  test('recordingClientPlatformIoValue is one of the supported platforms', () {
    const supported = <String>{'android', 'ios', 'macos', 'windows', 'linux'};
    expect(supported.contains(recordingClientPlatformIoValue()), isTrue);
  });
}
