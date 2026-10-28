import 'package:flutter/material.dart';

import 'package:enjoy_player/core/recovery/recovery_text_style.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class RecoveryErrorLayout extends StatelessWidget {
  const RecoveryErrorLayout({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class RecoveryErrorPanel extends StatelessWidget {
  const RecoveryErrorPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.busy,
    required this.onCopy,
    this.iconSize = 64,
    this.maxLines = 8,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String message;
  final bool busy;
  final VoidCallback onCopy;
  final double iconSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: iconSize, color: cs.error),
        SizedBox(height: t.space16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: t.space12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        SizedBox(height: t.space24),
        EnjoyCard(
          padding: EdgeInsets.all(t.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: recoveryMonoText(context, cs),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: t.space16),
              SizedBox(
                width: double.infinity,
                child: EnjoyButton.secondary(
                  icon: EnjoyIcons.copy,
                  onPressed: busy ? null : onCopy,
                  child: Text(l10n.recoveryCopyError),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
