library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
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
      leading: const Icon(Icons.translate_rounded),
      bodyBuilder: (ctx) {
        final auth = ref.watch(authCtrlProvider);
        return auth.when(
          data: (state) {
            if (state is! AuthSignedIn) {
              return const AuthRequiredCallout(
                surface: AuthRequiredSurface.lookupTranslation,
                compact: true,
              );
            }
            final async = ref.watch(lookupSheetTranslationProvider(params));
            return async.when(
              skipLoadingOnReload: true,
              data: (TranslationResult d) {
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
              error: (Object e, StackTrace st) {
                Object.hash(e.hashCode, st.hashCode);
                if (e is AuthFailure) {
                  return const AuthRequiredCallout(
                    surface: AuthRequiredSurface.lookupTranslation,
                    compact: true,
                  );
                }
                if (e is CreditsFailure) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LookupErrorRow(
                        message: lookupErrorUserMessage(e, l10n),
                        onRetry: () => ref.invalidate(
                          lookupSheetTranslationProvider(params),
                        ),
                        isRetrying: async.hasError && async.isLoading,
                      ),
                      TextButton(
                        onPressed: () => context.push('/subscription'),
                        child: Text(l10n.subscriptionViewPlans),
                      ),
                    ],
                  );
                }
                return LookupErrorRow(
                  message: lookupErrorUserMessage(e, l10n),
                  onRetry: () =>
                      ref.invalidate(lookupSheetTranslationProvider(params)),
                  isRetrying: async.hasError && async.isLoading,
                );
              },
            );
          },
          loading: () => const LookupSectionShimmer(),
          error: (Object e, StackTrace st) {
            Object.hash(e.hashCode, st.hashCode);
            return const AuthRequiredCallout(
              surface: AuthRequiredSurface.lookupTranslation,
              compact: true,
            );
          },
        );
      },
    );
  }
}
