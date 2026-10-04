/// Editorial sign-in screen — native provider hub and OTP flow.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/routing/auth_redirect.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/email_otp_sign_in_flow.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sign_in_flow_scaffold.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final auth = ref.watch(authCtrlProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen(authCtrlProvider, (_, next) {
      if (next.valueOrNull is AuthSignedIn && context.mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(resolvePostSignInPath(from));
      }
    });

    return SignInFlowScaffold(
      child: auth.when(
        data: (state) {
          if (state is AuthSignedIn) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(t.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      EnjoyIcons.checkCircleFill,
                      size: 72,
                      color: cs.primary,
                    ),
                    SizedBox(height: t.space24),
                    Text(
                      l10n.authSignedInSuccess,
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is AuthAwaitingOtp) {
            return OtpResumePane(otp: state);
          }
          if (state is AuthSigningInWebPkce) {
            return _WebPkceWaitingPane();
          }
          return const _SignInHub();
        },
        loading: () => const Center(child: SkeletonAppBootstrap()),
        error: (e, _) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: EnjoyThemeTokens.of(context).modalMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(t.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(EnjoyIcons.cloudOff, size: 56, color: cs.error),
                  SizedBox(height: t.space24),
                  Text(
                    l10n.errorNetwork,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge,
                  ),
                  SizedBox(height: t.space24),
                  EnjoyButton.brand(
                    onPressed: () => ref.invalidate(authCtrlProvider),
                    child: Text(l10n.retry),
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

class _SignInHub extends ConsumerWidget {
  const _SignInHub();

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      AppNotice.error(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(authCtrlProvider.notifier);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.modalMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space32,
              vertical: t.space40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: ShapeDecoration(
                    color: t.card,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(t.radiusXl),
                      side: BorderSide(color: t.hairline),
                    ),
                    shadows: [
                      BoxShadow(
                        color: t.auroraEnd.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: -6,
                        offset: const Offset(0, 12),
                      ),
                      ...t.shadowCard,
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SvgPicture.asset(
                      'assets/logo-light.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: t.space32),
                Text(
                  l10n.authSignInTitle,
                  textAlign: TextAlign.center,
                  style: enjoyDisplayStyle(
                    context,
                    size: 40,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: t.space12),
                Text(
                  l10n.authSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: t.space32),
                if (nativeGoogleSignInSupported) ...[
                  EnjoyButton.secondary(
                    size: EnjoyButtonSize.large,
                    expand: true,
                    icon: EnjoyIcons.google,
                    onPressed: () =>
                        _run(context, ref, notifier.signInWithGoogle),
                    child: Text(l10n.authContinueWithGoogle),
                  ),
                  SizedBox(height: t.space12 - 2),
                ],
                if (nativeAppleSignInSupported) ...[
                  EnjoyButton.secondary(
                    size: EnjoyButtonSize.large,
                    expand: true,
                    icon: EnjoyIcons.apple,
                    onPressed: () =>
                        _run(context, ref, notifier.signInWithApple),
                    child: Text(l10n.authContinueWithApple),
                  ),
                  SizedBox(height: t.space12 - 2),
                ],
                EnjoyButton.brand(
                  size: EnjoyButtonSize.large,
                  expand: true,
                  icon: EnjoyIcons.mail,
                  onPressed: () => context.push('/sign-in/email'),
                  child: Text(l10n.authContinueWithEmail),
                ),
                SizedBox(height: t.space24),
                Row(
                  children: [
                    Expanded(child: Divider(color: t.hairline)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: t.space12),
                      child: Text(
                        l10n.authOrDivider,
                        style: tt.labelMedium?.copyWith(color: t.textFaint),
                      ),
                    ),
                    Expanded(child: Divider(color: t.hairline)),
                  ],
                ),
                SizedBox(height: t.space12),
                EnjoyButton.ghost(
                  expand: true,
                  onPressed: () =>
                      _run(context, ref, notifier.startWebPkceSignIn),
                  child: Text(l10n.authOtherSignInOptions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmailEntryScreen extends ConsumerWidget {
  const EmailEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authCtrlProvider, (_, next) {
      if (next.valueOrNull is AuthSignedIn && context.mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(resolvePostSignInPath(from));
      }
    });

    return SignInFlowScaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            ref.read(authCtrlProvider.notifier).cancelSignIn();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sign-in');
            }
          },
        ),
        title: Text(l10n.authContinueWithEmail),
      ),
      child: const EmailOtpSignInFlow(),
    );
  }
}

class _WebPkceWaitingPane extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: t.space24),
            Text(
              l10n.authWebSignInWaiting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: t.space16),
            EnjoyButton.ghost(
              onPressed: () =>
                  ref.read(authCtrlProvider.notifier).cancelSignIn(),
              child: Text(l10n.authCancel),
            ),
          ],
        ),
      ),
    );
  }
}
