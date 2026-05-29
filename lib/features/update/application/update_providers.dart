/// Riverpod wiring for update strategies.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/features/update/application/direct_update_strategy.dart';
import 'package:enjoy_player/features/update/application/noop_update_strategy.dart';
import 'package:enjoy_player/features/update/application/update_strategy.dart';
import 'package:enjoy_player/features/update/data/version_manifest_repository.dart';

part 'update_providers.g.dart';

@Riverpod(keepAlive: true)
VersionManifestRepository versionManifestRepository(Ref ref) {
  return VersionManifestRepository();
}

@Riverpod(keepAlive: true)
UpdateStrategy updateStrategy(Ref ref) {
  if (!isDirectDistributionChannel) {
    return const NoOpUpdateStrategy();
  }
  return DirectUpdateStrategy(
    manifestRepository: ref.watch(versionManifestRepositoryProvider),
  );
}
