/// Shared failure card used by every Craft stage (audio, capture, rewrite).
///
/// Centralises the icon + localized message + action button layout so the
/// three stages render identical failure UX and route the same way:
///
/// * [CraftFailureAction.openAiSettings] → push `/settings/ai-providers`
/// * [CraftFailureAction.signIn]         → push `/sign-in`
/// * anything else (including the
///   [CraftFailureAction.switchToSpeakDirectly] case inherited from the
///   duplicated originals) falls back to the supplied [onRetry] callback.
///
/// Previously the same widget lived three times — one private copy each in
/// `audio_stage.dart`, `capture_stage.dart`, and `rewrite_stage.dart` —
/// see [issue #506](https://github.com/baizhiheizi/enjoy_player/issues/506).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CraftFailureCard extends StatelessWidget {
  const CraftFailureCard({
    required this.failure,
    required this.l10n,
    required this.onRetry,
    super.key,
  });

  final CraftFailure failure;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  String _actionLabel() {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        return l10n.craftOpenAiSettings;
      case CraftFailureAction.signIn:
        return l10n.craftSignInRequired;
      default:
        return l10n.craftRetry;
    }
  }

  void _handleAction(BuildContext context) {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        unawaited(context.push('/settings/ai-providers'));
        return;
      case CraftFailureAction.signIn:
        unawaited(context.push('/sign-in'));
        return;
      default:
        onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = Theme.of(context);
    final showCreditsCta = failure is CraftCreditsFailure;
    final light = theme.brightness == Brightness.light;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(t.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: t.sunk,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(t.radius2xl),
                    side: BorderSide(color: t.danger),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space32,
                    vertical: t.space32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: ShapeDecoration(
                          color: t.danger.withValues(alpha: light ? 0.12 : 0.2),
                          shape: CircleBorder(
                            side: BorderSide(
                              color: t.danger.withValues(
                                alpha: light ? 0.24 : 0.34,
                              ),
                            ),
                          ),
                        ),
                        child: Icon(
                          EnjoyIcons.errorFill,
                          size: 28,
                          color: t.danger,
                        ),
                      ),
                      SizedBox(height: t.space16),
                      Text(
                        failure.message(l10n),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: t.space24),
                      EnjoyButton.destructive(
                        onPressed: () => _handleAction(context),
                        child: Text(_actionLabel()),
                      ),
                      if (showCreditsCta) ...[
                        SizedBox(height: t.space8),
                        EnjoyButton.ghost(
                          onPressed: () =>
                              unawaited(context.push('/subscription')),
                          child: Text(creditsCtaLabel(l10n)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
