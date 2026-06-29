/// Reusable “sign in to use this feature” UI for Enjoy account–gated flows.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Where the user was when auth was required (appended to `/sign-in?from=`).
enum AuthRequiredSurface {
  lookupTranslation,
  lookupDictionary,
  lookupContextual,
  cloud,
  sync,
  credits,
}

extension AuthRequiredSurfaceX on AuthRequiredSurface {
  String get fromQueryParam => switch (this) {
    AuthRequiredSurface.lookupTranslation => 'lookup_translation',
    AuthRequiredSurface.lookupDictionary => 'lookup_dictionary',
    AuthRequiredSurface.lookupContextual => 'lookup_contextual',
    AuthRequiredSurface.cloud => 'cloud',
    AuthRequiredSurface.sync => 'sync',
    AuthRequiredSurface.credits => 'credits',
  };

  /// Title + body for the callout (localized).
  (String title, String body) messages(AppLocalizations l10n) => switch (this) {
    AuthRequiredSurface.lookupTranslation ||
    AuthRequiredSurface.lookupDictionary ||
    AuthRequiredSurface.lookupContextual => (
      l10n.authRequiredCloudFeaturesTitle,
      l10n.lookupCloudRequiresSignIn,
    ),
    AuthRequiredSurface.cloud => (
      l10n.cloudScreenTitle,
      l10n.cloudSignedOutBody,
    ),
    AuthRequiredSurface.sync => (
      l10n.syncScreenTitle,
      l10n.syncScreenSignedOutBody,
    ),
    AuthRequiredSurface.credits => (
      l10n.creditsUsageTitle,
      l10n.syncScreenSignedOutBody,
    ),
  };

  String? get _illustrationAsset => switch (this) {
    AuthRequiredSurface.cloud => EnjoyIllustrations.emptyCloud,
    AuthRequiredSurface.sync ||
    AuthRequiredSurface.credits => EnjoyIllustrations.offline,
    _ => null,
  };
}

/// Shows a sign-in CTA when the user is not [AuthSignedIn].
///
/// [compact] fits lookup sheet sections; full layout uses [EmptyState].
class AuthRequiredCallout extends ConsumerWidget {
  const AuthRequiredCallout({
    required this.surface,
    this.compact = false,
    super.key,
  });

  final AuthRequiredSurface surface;
  final bool compact;

  void _openSignIn(BuildContext context) {
    unawaited(context.push('/sign-in?from=${surface.fromQueryParam}'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return auth.when(
      data: (state) {
        if (state is AuthSignedIn) {
          return const SizedBox.shrink();
        }
        final (title, body) = surface.messages(l10n);
        if (compact) {
          return _CompactCallout(
            title: title,
            body: body,
            buttonLabel: l10n.syncScreenGoSignIn,
            onSignIn: () => _openSignIn(context),
          );
        }
        final illust = surface._illustrationAsset;
        return EmptyState(
          icon: Icons.lock_person_outlined,
          illustrationAsset: illust,
          title: title,
          subtitle: body,
          action: () => _openSignIn(context),
          actionLabel: l10n.syncScreenGoSignIn,
        );
      },
      loading: () => compact
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Skeleton.line(width: double.infinity),
                  const SizedBox(height: 8),
                  Skeleton.line(width: double.infinity, height: 12),
                  const SizedBox(height: 8),
                  Skeleton.line(width: 140, height: 12),
                ],
              ),
            )
          : const SkeletonMediaList(),
      error: (Object error, StackTrace stackTrace) {
        Object.hash(error.hashCode, stackTrace.hashCode);
        final (title, body) = surface.messages(l10n);
        if (compact) {
          return _CompactCallout(
            title: title,
            body: body,
            buttonLabel: l10n.syncScreenGoSignIn,
            onSignIn: () => _openSignIn(context),
          );
        }
        return EmptyState(
          icon: Icons.lock_person_outlined,
          illustrationAsset: surface._illustrationAsset,
          title: title,
          subtitle: body,
          action: () => _openSignIn(context),
          actionLabel: l10n.syncScreenGoSignIn,
        );
      },
    );
  }
}

class _CompactCallout extends StatelessWidget {
  const _CompactCallout({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onSignIn,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_person_outlined, color: cs.primary, size: 22),
                SizedBox(width: t.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: t.space4),
                      Text(
                        body,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space12),
            EnjoyButton.primary(
              icon: Icons.login_rounded,
              onPressed: onSignIn,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
