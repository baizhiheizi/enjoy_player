/// Sidebar account entry: sign-in or profile shortcut.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SidebarAccountChip extends ConsumerWidget {
  const SidebarAccountChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authCtrlProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space8, 0, t.space8, t.space8),
      child: auth.when(
        data: (state) {
          if (authFlowInProgress(state)) {
            return ListTile(
              dense: true,
              leading: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
              title: Text(
                state is AuthAwaitingOtp
                    ? l10n.authOtpTitle
                    : l10n.authWebSignInWaiting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () => context.push(
                state is AuthAwaitingOtp ? '/sign-in/email' : '/sign-in',
              ),
            );
          }
          if (state is AuthSignedIn) {
            final p = state.profile;
            final avatarUrl = p.avatarUrl;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(Icons.person_rounded, size: 18, color: cs.primary)
                    : null,
              ),
              title: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              subtitle: Text(
                l10n.settingsAccountOpenProfile,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.primary),
              ),
              onTap: () => context.push('/profile'),
            );
          }
          return ListTile(
            dense: true,
            leading: Icon(Icons.login_rounded, color: cs.primary, size: 22),
            title: Text(
              l10n.settingsAccountSignIn,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () => context.push('/sign-in'),
          );
        },
        loading: () => const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (Object e, StackTrace s) => const SizedBox.shrink(),
      ),
    );
  }
}
