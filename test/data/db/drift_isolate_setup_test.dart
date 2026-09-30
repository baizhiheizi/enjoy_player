import 'package:enjoy_player/data/db/drift_isolate_setup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native options carry an isolate setup hook', () {
    final token = ServicesBinding.rootIsolateToken;

    final options = driftNativeOptions(token!);

    expect(options.isolateSetup, isNotNull);
  });

  test('default options resolve a root token once a binding exists', () {
    expect(defaultDriftNativeOptions(), isNotNull);
  });

  test('background messenger setup is safe to call more than once', () {
    final token = ServicesBinding.rootIsolateToken!;

    expect(() => initializeDriftBackgroundIsolate(token), returnsNormally);
    expect(
      () => initializeDriftBackgroundIsolate(token),
      returnsNormally,
      reason: 'drift runs isolateSetup on both the worker and read-pool',
    );
  });
}
