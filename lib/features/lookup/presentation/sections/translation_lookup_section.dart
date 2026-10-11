library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_error_widget.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_auth_gate.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
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

    return LookupExpansionCard(
      title: l10n.lookupSectionTranslation,
      initiallyExpanded: true,
      leading: const Icon(EnjoyIcons.translate),
      bodyBuilder: (ctx) => LookupSectionAuthGate(
        surface: AuthRequiredSurface.lookupTranslation,
        child: Builder(
          builder: (_) {
            final async = ref.watch(lookupSheetTranslationProvider(params));
            return async.when(
              skipLoadingOnReload: true,
              data: (TranslationResult d) {
                scheduleLookupCreditsClear(
                  context,
                  ref,
                  LookupSectionId.translation,
                );
                if (d.translatedText.trim().isEmpty) {
                  return Text(
                    l10n.lookupEmpty,
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return SelectableText(
                  d.translatedText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
              loading: () => const LookupSectionShimmer(),
              error: (Object e, StackTrace st) => lookupSectionErrorWidget(
                context: context,
                ref: ref,
                l10n: l10n,
                section: LookupSectionId.translation,
                surface: AuthRequiredSurface.lookupTranslation,
                error: e,
                onRetry: () =>
                    ref.invalidate(lookupSheetTranslationProvider(params)),
                isRetrying: async.hasError && async.isLoading,
              ),
            );
          },
        ),
      ),
    );
  }
}
