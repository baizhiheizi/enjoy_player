/// Editorial error-state primitive (Duet) — the async `error:` counterpart
/// to [EmptyState].
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../enjoy_tokens.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(t.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(EnjoyIcons.error, size: 48, color: cs.error),
              SizedBox(height: t.space16),
              Text(message, textAlign: TextAlign.center, style: tt.bodyLarge),
              if (onRetry != null) ...[
                SizedBox(height: t.space16),
                EnjoyButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
