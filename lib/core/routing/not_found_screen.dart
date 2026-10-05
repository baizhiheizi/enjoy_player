/// Fallback screen for unknown go_router locations.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: EdgeInsets.all(t.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RotatedBox(
                    quarterTurns: 2,
                    child: EnjoyLogoMark(size: 132, opacity: 0.55),
                  ),
                  SizedBox(height: t.space20),
                  Text(
                    l10n.notFoundTitle,
                    textAlign: TextAlign.center,
                    style: enjoyDisplayStyle(
                      context,
                      size: 40,
                      height: 1.12,
                      letterSpacing: -0.8,
                      color: tt.displaySmall?.color,
                    ),
                  ),
                  SizedBox(height: t.space12 - 2),
                  Text(
                    l10n.notFoundSubtitle(uri.toString()),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.6,
                      color: t.ink2,
                    ),
                  ),
                  SizedBox(height: t.space24),
                  EnjoyButton.brand(
                    onPressed: () => context.go('/'),
                    child: Text(l10n.notFoundBackHome),
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
