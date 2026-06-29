/// Fallback screen for unknown go_router locations.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: EdgeInsets.all(t.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_off_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: t.space24),
                  Text(
                    l10n.notFoundTitle,
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall,
                  ),
                  SizedBox(height: t.space12),
                  Text(
                    l10n.notFoundSubtitle(uri.toString()),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: t.space32),
                  SizedBox(
                    width: double.infinity,
                    child: EnjoyButton.primary(
                      onPressed: () => context.go('/'),
                      child: Text(l10n.notFoundBackHome),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
