import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/update/application/update_evaluator.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

ReleaseManifest manifest({
  String version = '0.2.0',
  String minSupported = '0.1.0',
}) {
  return ReleaseManifest(
    version: version,
    build: 2,
    minSupportedVersion: minSupported,
    notes: 'Bug fixes',
    assets: const {},
  );
}

void main() {
  test('up to date when current >= remote', () {
    final result = evaluateUpdate(
      currentVersion: '0.2.0',
      manifest: manifest(version: '0.2.0'),
    );
    expect(result.hasUpdate, isFalse);
  });

  test('optional update when newer remote and not snoozed', () {
    final result = evaluateUpdate(
      currentVersion: '0.1.0',
      manifest: manifest(version: '0.2.0'),
    );
    expect(result.availability, UpdateAvailability.updateAvailable);
    expect(result.release?.severity, UpdateSeverity.optional);
  });

  test('mandatory when below minSupportedVersion', () {
    final result = evaluateUpdate(
      currentVersion: '0.1.0',
      manifest: manifest(version: '0.3.0', minSupported: '0.2.0'),
    );
    expect(result.availability, UpdateAvailability.mandatoryUpdate);
    expect(result.release?.severity, UpdateSeverity.mandatory);
  });

  test('snooze suppresses optional prompt', () {
    final until = DateTime.utc(2099, 1, 1);
    final result = evaluateUpdate(
      currentVersion: '0.1.0',
      manifest: manifest(version: '0.2.0'),
      snoozedVersion: '0.2.0',
      snoozeUntil: until,
      now: DateTime.utc(2026, 1, 1),
    );
    expect(result.hasUpdate, isFalse);
  });
}
