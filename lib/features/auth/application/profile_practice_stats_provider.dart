/// Local-only aggregates for the signed-in profile stats row.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';

class ProfilePracticeStats {
  const ProfilePracticeStats({
    required this.libraryItemCount,
    required this.echoSessionCount,
    required this.recordedPracticeMinutes,
  });

  final int libraryItemCount;
  final int echoSessionCount;
  final int recordedPracticeMinutes;
}

final profilePracticeStatsProvider =
    FutureProvider.autoDispose<ProfilePracticeStats>((ref) async {
      final db = ref.watch(appDatabaseProvider);
      final totals = await db.echoSessionDao.practiceTotals();
      final libraryCount = ref.watch(libraryMediaProvider).maybeWhen(
        data: (m) => m.length,
        orElse: () => 0,
      );
      return ProfilePracticeStats(
        libraryItemCount: libraryCount,
        echoSessionCount: totals.sessionCount,
        recordedPracticeMinutes: (totals.recordingsDurationMs / 60000).floor(),
      );
    });
