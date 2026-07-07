/// Account hero — signed-in identity card or sign-in prompt.
///
/// Extracted 1:1 from the pre-redesign `_AccountHeroCard`/`_AccountHeroSkeleton`
/// in `settings_screen.dart`; preserves the signed-in/out/loading/error states.
/// Unlike the other sections, this renders its own gradient hero banner
/// (including its own section label) rather than a [SettingsSectionCard].
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class AccountHeroSection extends ConsumerWidget {
  const AccountHeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider);

    return auth.when(
      data: (state) {
        if (state is AuthSignedIn) {
          final avatarUrl = rasterAvatarUrl(state.profile.avatarUrl);
          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
          return _AccountHeroCard(
            sectionLabel: l10n.settingsSectionAccount,
            sectionHint: l10n.settingsSectionAccountHint,
            name: state.profile.name,
            email: state.profile.email,
            signedIn: true,
            primaryActionLabel: l10n.settingsAccountOpenProfile,
            onPrimaryAction: () => context.push('/profile'),
            avatar: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              radius: 28,
              backgroundImage: hasAvatar
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: hasAvatar
                  ? null
                  : Text(
                      (state.profile.name.isNotEmpty
                              ? state.profile.name[0]
                              : '?')
                          .toUpperCase(),
                      style: tt.titleLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          );
        }
        return _AccountHeroCard(
          sectionLabel: l10n.settingsSectionAccount,
          sectionHint: l10n.settingsSectionAccountHint,
          name: l10n.settingsAccountSignIn,
          email: l10n.settingsAccountSignedOut,
          signedIn: false,
          primaryActionLabel: l10n.settingsAccountSignIn,
          onPrimaryAction: () => context.push('/sign-in'),
          avatar: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest.withValues(
              alpha: 0.9,
            ),
            radius: 28,
            child: Icon(
              Icons.person_outline_rounded,
              size: 32,
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      },
      loading: () => const _AccountHeroSkeleton(),
      error: (Object e, StackTrace s) => Padding(
        padding: EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(t.radiusLg),
            border: Border.all(color: cs.error.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsAuthLoadFailed,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: t.space12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(authCtrlProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeroCard extends StatelessWidget {
  const _AccountHeroCard({
    required this.sectionLabel,
    required this.sectionHint,
    required this.name,
    required this.email,
    required this.signedIn,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.avatar,
  });

  final String sectionLabel;
  final String sectionHint;
  final String name;
  final String email;
  final bool signedIn;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.gradientStart.withValues(alpha: 0.94),
                t.gradientEnd.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sectionLabel.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  sectionHint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: t.space16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    SizedBox(width: t.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.35,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: t.space8),
                          Text(
                            email,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.82),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.space20),
                EnjoyButton.secondary(
                  onPressed: onPrimaryAction,
                  icon: signedIn
                      ? Icons.manage_accounts_outlined
                      : Icons.login_rounded,
                  child: Text(primaryActionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeroSkeleton extends StatelessWidget {
  const _AccountHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - t.space32;
            return Skeleton.box(
              width: w,
              height: 188,
              borderRadius: BorderRadius.circular(t.radiusXl),
            );
          },
        ),
      ),
    );
  }
}
