/// Pure formatters shared by the credits usage filters, table, and card views.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

String serviceTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'tts' => l10n.creditsServiceTypeTts,
    'asr' => l10n.creditsServiceTypeAsr,
    'translation' => l10n.creditsServiceTypeTranslation,
    'llm' => l10n.creditsServiceTypeLlm,
    'assessment' => l10n.creditsServiceTypeAssessment,
    _ => type,
  };
}

IconData serviceTypeIcon(String serviceType) {
  return switch (serviceType) {
    'tts' => EnjoyIcons.speak,
    'asr' => EnjoyIcons.mic,
    'translation' => EnjoyIcons.translate,
    'llm' => EnjoyIcons.robot,
    'assessment' => EnjoyIcons.vocabulary,
    _ => EnjoyIcons.receipt,
  };
}

String tierLabel(AppLocalizations l10n, String tier) => tier.isEmpty
    ? tier
    : subscriptionTierLabel(l10n, subscriptionTierFromJson(tier));
