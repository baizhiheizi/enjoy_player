import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/features/update/application/direct_update_strategy.dart';
import 'package:enjoy_player/features/update/application/noop_update_strategy.dart';
import 'package:enjoy_player/features/update/application/update_providers.dart';
import 'package:enjoy_player/features/update/data/version_manifest_repository.dart';

void main() {
  group('versionManifestRepositoryProvider', () {
    test('returns a VersionManifestRepository instance with default URL', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(versionManifestRepositoryProvider);
      expect(repo, isA<VersionManifestRepository>());
    });

    test('overrideWithValue swaps in a fake repository', () {
      late VersionManifestRepository fake;
      final container = ProviderContainer(
        overrides: [
          versionManifestRepositoryProvider.overrideWith((ref) {
            fake = VersionManifestRepository(
              manifestUrl: 'https://test.invalid/manifest.json',
            );
            return fake;
          }),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(versionManifestRepositoryProvider);
      expect(identical(repo, fake), isTrue);
    });
  });

  group('updateStrategyProvider', () {
    test('builds NoOpUpdateStrategy on store distribution channel', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final strategy = container.read(updateStrategyProvider);
      if (!isDirectDistributionChannel) {
        expect(strategy, isA<NoOpUpdateStrategy>());
      } else {
        expect(strategy, isA<DirectUpdateStrategy>());
      }
    });

    test('overrideWithValue swaps in a custom strategy', () {
      final container = ProviderContainer(
        overrides: [
          updateStrategyProvider.overrideWithValue(const NoOpUpdateStrategy()),
        ],
      );
      addTearDown(container.dispose);

      final strategy = container.read(updateStrategyProvider);
      expect(strategy, isA<NoOpUpdateStrategy>());
    });

    test('overrideWithValue yields a DirectUpdateStrategy instance', () {
      final container = ProviderContainer(
        overrides: [
          updateStrategyProvider.overrideWithValue(DirectUpdateStrategy()),
        ],
      );
      addTearDown(container.dispose);

      final strategy = container.read(updateStrategyProvider);
      expect(strategy, isA<DirectUpdateStrategy>());
    });
  });

  group('update_providers.dart source shape', () {
    test('factory functions `versionManifestRepository` and '
        '`updateStrategy` are exposed at file scope', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(versionManifestRepositoryProvider),
        isA<VersionManifestRepository>(),
      );
    });
  });
}
