/// Remote learning stats for the signed-in profile practice row.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/api/services/stats_api_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';

final profilePracticeStatsProvider =
    FutureProvider.autoDispose<LearningStatistics>((ref) async {
      final auth = ref.watch(authCtrlProvider).valueOrNull;
      if (auth is! AuthSignedIn) {
        throw StateError('Profile stats require a signed-in session');
      }

      final api = ref.watch(statsApiProvider);
      final json = await api
          .learningStatistics(timezone: DateTime.now().timeZoneName)
          .timeout(const Duration(seconds: 15));
      return LearningStatistics.fromJson(json);
    });
