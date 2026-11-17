library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_refresh.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_ai_section_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranslationLookupSection extends ConsumerWidget {
  const TranslationLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = LookupTranslationParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
    );
    final theme = Theme.of(context);

    void forceRefresh() {
      forceRefreshLookupSection<TranslationResult>(
        ref: ref,
        cache: ref.read(aiTranslationCacheProvider),
        kind: AiKind.translation,
        key: lookupTranslationCacheKey(params),
        invalidateProvider: () =>
            ref.invalidate(lookupSheetTranslationProvider(params)),
      );
    }

    return LookupAiSectionCard<TranslationResult>(
      title: l10n.lookupSectionTranslation,
      initiallyExpanded: true,
      leading: const Icon(EnjoyIcons.translate),
      surface: AuthRequiredSurface.lookupTranslation,
      section: LookupSectionId.translation,
      provider: lookupSheetTranslationProvider(params),
      onRetry: forceRefresh,
      bodyBuilder: (context, d, async) {
        if (d.translatedText.trim().isEmpty) {
          return Text(l10n.lookupEmpty, style: theme.textTheme.bodyMedium);
        }
        return SelectableText(
          d.translatedText,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}
