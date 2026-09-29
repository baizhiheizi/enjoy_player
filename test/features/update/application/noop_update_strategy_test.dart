import 'package:enjoy_player/features/update/application/noop_update_strategy.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoOpUpdateStrategy.checkForUpdate', () {
    const strategy = NoOpUpdateStrategy();

    test(
      'returns upToDate even when current version is older-looking',
      () async {
        expect(
          await strategy.checkForUpdate(currentVersion: '0.0.1'),
          const UpdateCheckResult.upToDate(),
        );
      },
    );

    test('ignores snooze fields (always upToDate)', () async {
      final result = await strategy.checkForUpdate(
        currentVersion: '1.2.3',
        snoozedVersion: '9.9.9',
        snoozeUntil: DateTime.utc(2099, 1, 1),
      );
      expect(result, const UpdateCheckResult.upToDate());
      expect(result.availability, UpdateAvailability.upToDate);
    });
  });

  group('NoOpUpdateStrategy.applyUpdate', () {
    const strategy = NoOpUpdateStrategy();

    test('yields exactly one UpdateInstallProgress.completed()', () async {
      final release = const AppRelease(
        manifest: ReleaseManifest(
          version: '1.0.0',
          build: 1,
          minSupportedVersion: '0.0.0',
          notes: '',
          assets: {},
        ),
        severity: UpdateSeverity.optional,
        currentVersion: '0.9.0',
      );

      final phases = <UpdateInstallProgress>[];
      await for (final phase in strategy.applyUpdate(release)) {
        phases.add(phase);
      }
      expect(phases, hasLength(1));
      expect(phases.single, const UpdateInstallProgress.completed());
      expect(phases.single.phase, UpdateInstallPhase.completed);
    });

    test('does not consult the release or severity', () async {
      final mandatoryRelease = const AppRelease(
        manifest: ReleaseManifest(
          version: '9.9.9',
          build: 99,
          minSupportedVersion: '9.0.0',
          notes: '',
          assets: {},
        ),
        severity: UpdateSeverity.mandatory,
        currentVersion: '1.0.0',
      );

      final phases = <UpdateInstallProgress>[];
      await for (final phase in strategy.applyUpdate(mandatoryRelease)) {
        phases.add(phase);
      }
      expect(phases.single.phase, UpdateInstallPhase.completed);
    });
  });

  group('NoOpUpdateStrategy.cancelUpdate', () {
    test('returns a Future that completes without throwing', () async {
      const strategy = NoOpUpdateStrategy();
      await strategy.cancelUpdate();
      await strategy.cancelUpdate();
    });
  });
}
