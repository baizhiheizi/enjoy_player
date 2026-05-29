/// Store-channel builds: platform owns updates (TestFlight / Play).
library;

import 'package:enjoy_player/features/update/application/update_strategy.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

class NoOpUpdateStrategy implements UpdateStrategy {
  const NoOpUpdateStrategy();

  @override
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
    String? snoozedVersion,
    DateTime? snoozeUntil,
  }) async {
    return const UpdateCheckResult.upToDate();
  }

  @override
  Future<void> applyUpdate(AppRelease release) async {}
}
