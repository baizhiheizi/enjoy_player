/// Worker credits wallet summary (daily + permanent).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/services/ai/ai_api_providers.dart';
import 'package:enjoy_player/features/credits/domain/credits_summary.dart';

part 'credits_summary_provider.g.dart';

@Riverpod(keepAlive: false)
Future<CreditsSummary> creditsSummary(Ref ref) {
  return ref.watch(creditsApiProvider).getSummary();
}
