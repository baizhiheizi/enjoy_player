library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/routing/route_paths.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_callout.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LookupCreditsBanner extends StatelessWidget {
  const LookupCreditsBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return LookupCallout(
      icon: EnjoyIcons.wallet,
      iconColor: t.ink2,
      message: message,
      backgroundColor: t.sunk,
      action: EnjoyButton.brand(
        size: EnjoyButtonSize.small,
        onPressed: () => context.push(kSubscriptionRoutePath),
        child: Text(creditsCtaLabel(l10n)),
      ),
    );
  }
}
