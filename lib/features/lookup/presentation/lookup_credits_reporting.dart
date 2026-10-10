library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';

void scheduleLookupCreditsReport(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section,
  String message,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ref.invalidate(creditsSummaryProvider);
    ref.read(lookupCreditsExhaustedProvider.notifier).report(section, message);
  });
}

void scheduleLookupCreditsClear(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section,
) {
  final notifier = ref.read(lookupCreditsExhaustedProvider.notifier);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    notifier.clear(section);
  });
}
