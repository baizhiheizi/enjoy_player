/// Editorial sign-in screen — native provider hub and OTP flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
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
        context.go('/');
      }
    });

    return SignInFlowScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => _close(context, ref),
        ),
      ),
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
                      Icons.check_circle_rounded,
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
          return _SignInHub(onClose: () => _close(context, ref));
        },
        loading: () => const Center(child: SkeletonAppBootstrap()),
        error: (e, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: EdgeInsets.all(t.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
                  SizedBox(height: t.space24),
                  Text(
                    l10n.errorNetwork,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge,
                  ),
                  SizedBox(height: t.space24),
                  EnjoyButton.primary(
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

  void _close(BuildContext context, WidgetRef ref) {
    ref.read(authCtrlProvider.notifier).cancelSignIn();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _SignInHub extends ConsumerWidget {
  const _SignInHub({required this.onClose});

  final VoidCallback onClose;

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
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space32,
              vertical: t.space40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(t.radiusXl),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
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
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                  SizedBox(
                    width: double.infinity,
                    child: EnjoyButton.primary(
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: () =>
                          _run(context, ref, notifier.signInWithGoogle),
                      child: Text(l10n.authContinueWithGoogle),
                    ),
                  ),
                  SizedBox(height: t.space12),
                ],
                if (nativeAppleSignInSupported) ...[
                  SizedBox(
                    width: double.infinity,
                    child: EnjoyButton.primary(
                      icon: Icons.apple_rounded,
                      onPressed: () =>
                          _run(context, ref, notifier.signInWithApple),
                      child: Text(l10n.authContinueWithApple),
                    ),
                  ),
                  SizedBox(height: t.space12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: EnjoyButton.primary(
                    icon: Icons.mail_outline_rounded,
                    onPressed: () => context.push('/sign-in/email'),
                    child: Text(l10n.authContinueWithEmail),
                  ),
                ),
                SizedBox(height: t.space20),
                Text(
                  l10n.authOrDivider,
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: t.space12),
                SizedBox(
                  width: double.infinity,
                  child: EnjoyButton.ghost(
                    onPressed: () =>
                        _run(context, ref, notifier.startWebPkceSignIn),
                    child: Text(l10n.authOtherSignInOptions),
                  ),
                ),
                SizedBox(height: t.space12),
                SizedBox(
                  width: double.infinity,
                  child: EnjoyButton.ghost(
                    onPressed: onClose,
                    child: Text(l10n.authCancel),
                  ),
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
