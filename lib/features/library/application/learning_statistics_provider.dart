/// Fetches `/api/v1/mine/stats` when the user is signed in.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/utils/client_timezone.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';

part 'learning_statistics_provider.g.dart';

final Logger _statsLog = logNamed('stats');

@riverpod
Future<LearningStatistics?> learningStatistics(Ref ref) async {
  final authState = ref.watch(authCtrlProvider);
  final auth = authState.valueOrNull;
  if (auth is! AuthSignedIn) return null;

  final api = ref.watch(statsApiProvider);
  final sw = Stopwatch()..start();
  _statsLog.info('stats: learningStatistics request start');
  try {
    final json = await api
        .learningStatistics(timezone: await clientTimezoneId())
        .timeout(const Duration(seconds: 15));
    _statsLog.info(
      'stats: learningStatistics done in ${sw.elapsedMilliseconds}ms',
    );
    return LearningStatistics.fromJson(json);
  } catch (e, st) {
    _statsLog.warning(
      'stats: learningStatistics failed after ${sw.elapsedMilliseconds}ms',
      e,
      st,
    );
    return LearningStatistics.empty();
  }
}
