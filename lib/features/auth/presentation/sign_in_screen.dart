/// Browser-based Enjoy sign-in (`start_auth` + `poll`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final auth = ref.watch(authCtrlProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authSignInTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(authCtrlProvider.notifier).cancelSignIn();
            context.pop();
          },
        ),
      ),
      body: auth.when(
        data: (state) {
          if (state is AuthSigningIn) {
            return Padding(
              padding: EdgeInsets.all(t.space24),
              child: GlassSurface(
                child: Padding(
                  padding: EdgeInsets.all(t.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 48, color: cs.primary),
                      SizedBox(height: t.space16),
                      Text(
                        l10n.authWaitingForApproval,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: t.space24),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(authCtrlProvider.notifier).cancelSignIn();
                          context.pop();
                        },
                        child: Text(l10n.authCancel),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.all(t.space24),
            child: GlassSurface(
              child: Padding(
                padding: EdgeInsets.all(t.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authSignInTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: t.space16),
                    Text(
                      l10n.authSignInSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(height: t.space32),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref.read(authCtrlProvider.notifier).startSignIn();
                      },
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: Text(l10n.authSignInCta),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
