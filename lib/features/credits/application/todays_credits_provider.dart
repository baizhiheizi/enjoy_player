/// Riverpod: fetch total AI credits consumed today from Worker.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/services/ai/ai_api_providers.dart';

part 'todays_credits_provider.g.dart';

@Riverpod(keepAlive: false)
Future<int> todaysCreditsUsed(Ref ref) async {
  final api = ref.watch(creditsApiProvider);
  final today = DateTime.now().toUtc();
  final ymd =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final page = await api.getUsages(startDate: ymd, endDate: ymd, limit: 1);

  if (page.logs.isEmpty) return 0;
  return page.logs.first.usedAfter;
}
