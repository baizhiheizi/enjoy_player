/// Shared shell for the lookup sheet sections.
///
/// Every lookup section renders the same scaffold: an expandable tonal card
/// whose body is gated behind the signed-in check. The body is built only
/// after the gate lets it through, so a signed-out reader never triggers the
/// section's provider — and therefore never spends a credit.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_error_widget.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_auth_gate.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The expandable card plus auth gate every lookup sheet section renders.
class LookupSectionShell extends StatelessWidget {
  const LookupSectionShell({
    required this.title,
    required this.initiallyExpanded,
    required this.surface,
    required this.bodyBuilder,
    this.leading,
    super.key,
  });

  final String title;
  final bool initiallyExpanded;
  final Widget? leading;
  final AuthRequiredSurface surface;

  /// Built inside the auth gate, so it runs only for a signed-in reader.
  final Widget Function(BuildContext context) bodyBuilder;

  @override
  Widget build(BuildContext context) {
    return LookupExpansionCard(
      title: title,
      initiallyExpanded: initiallyExpanded,
      leading: leading,
      bodyBuilder: (_) => LookupSectionAuthGate(
        surface: surface,
        child: Builder(builder: bodyBuilder),
      ),
    );
  }
}

/// A lookup sheet section whose body comes from a provider-backed value.
///
/// Owns the whole async shell — the auth gate, the loading shimmer, the
/// shared error surface and the credits bookkeeping — so a section only
/// describes its own body.
class LookupAiSectionCard<T> extends ConsumerWidget {
  const LookupAiSectionCard({
    required this.title,
    required this.initiallyExpanded,
    required this.leading,
    required this.surface,
    required this.section,
    required this.provider,
    required this.onRetry,
    required this.bodyBuilder,
    super.key,
  });

  final String title;
  final bool initiallyExpanded;
  final Widget leading;
  final AuthRequiredSurface surface;
  final LookupSectionId section;

  /// Watched inside the auth gate, never while signed out.
  final ProviderListenable<AsyncValue<T>> provider;

  /// Re-attempts the section's fetch.
  final VoidCallback onRetry;

  final Widget Function(BuildContext context, T data, AsyncValue<T> value)
  bodyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return LookupSectionShell(
      title: title,
      initiallyExpanded: initiallyExpanded,
      leading: leading,
      surface: surface,
      bodyBuilder: (_) => Builder(
        builder: (_) {
          final async = ref.watch(provider);
          return async.when(
            skipLoadingOnReload: true,
            data: (T data) {
              scheduleLookupCreditsClear(
                context,
                ref,
                section,
                resultToken: data,
              );
              return bodyBuilder(context, data, async);
            },
            loading: () => const LookupSectionShimmer(),
            error: (Object e, StackTrace st) => lookupSectionErrorWidget(
              context: context,
              ref: ref,
              l10n: l10n,
              section: section,
              surface: surface,
              error: e,
              onRetry: onRetry,
              isRetrying: async.hasError && async.isLoading,
            ),
          );
        },
      ),
    );
  }
}
