library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';

final Map<LookupSectionId, Object> _lastTokenPerSection =
    <LookupSectionId, Object>{};

@visibleForTesting
void resetLookupCreditsReportingForTest() => _lastTokenPerSection.clear();

void scheduleLookupCreditsReport(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section,
  String message, {
  Object? resultToken,
}) {
  _refreshCreditsSummary(context, ref, section, resultToken);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ref.read(lookupCreditsExhaustedProvider.notifier).report(section, message);
  });
}

void scheduleLookupCreditsClear(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section, {
  Object? resultToken,
}) {
  _refreshCreditsSummary(context, ref, section, resultToken);
  final notifier = ref.read(lookupCreditsExhaustedProvider.notifier);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    notifier.clear(section);
  });
}

void _refreshCreditsSummary(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section,
  Object? resultToken,
) {
  if (resultToken != null) {
    if (identical(_lastTokenPerSection[section], resultToken)) return;
    _lastTokenPerSection[section] = resultToken;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ref.invalidate(creditsSummaryProvider);
  });
}
