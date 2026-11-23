library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_callout.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';

class LookupCreditsBanner extends StatelessWidget {
  const LookupCreditsBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);

    return LookupCallout(
      icon: EnjoyIcons.wallet,
      iconColor: t.ink2,
      message: message,
      backgroundColor: t.sunk,
      action: const CreditsCtaButton(style: CreditsCtaStyle.brand),
    );
  }
}
