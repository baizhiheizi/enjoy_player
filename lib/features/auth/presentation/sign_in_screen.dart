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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => _close(context, ref),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.gradientStart, t.gradientEnd],
              ),
            ),
          ),
          auth.when(
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
                return _OtpEntryPane(
                  email: state.email,
                  resendAfterSeconds: state.resendAfterSeconds,
                );
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
        ],
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

class EmailEntryScreen extends ConsumerStatefulWidget {
  const EmailEntryScreen({super.key});

  @override
  ConsumerState<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends ConsumerState<EmailEntryScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppNotice.error(context, AppLocalizations.of(context)!.authEmailInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authCtrlProvider.notifier).sendOtp(email: email);
      if (!mounted) return;
      context.pop();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppNotice.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authContinueWithEmail)),
      body: Padding(
        padding: EdgeInsets.all(t.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.authEmailPrompt),
            SizedBox(height: t.space16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: t.space24),
            EnjoyButton.primary(
              onPressed: _busy ? null : _submit,
              child: Text(l10n.authSendOtp),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpEntryPane extends ConsumerStatefulWidget {
  const _OtpEntryPane({required this.email, required this.resendAfterSeconds});

  final String email;
  final int resendAfterSeconds;

  @override
  ConsumerState<_OtpEntryPane> createState() => _OtpEntryPaneState();
}

class _OtpEntryPaneState extends ConsumerState<_OtpEntryPane> {
  final _controller = TextEditingController();
  bool _busy = false;
  late int _resendSecondsLeft;

  @override
  void initState() {
    super.initState();
    _resendSecondsLeft = widget.resendAfterSeconds;
    _tickResend();
  }

  void _tickResend() {
    if (_resendSecondsLeft <= 0) return;
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _resendSecondsLeft--);
      _tickResend();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authCtrlProvider.notifier)
          .verifyOtp(code: _controller.text.trim());
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppNotice.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSecondsLeft > 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(authCtrlProvider.notifier).resendOtp();
      final next = ref.read(authCtrlProvider).valueOrNull;
      if (next is AuthAwaitingOtp && mounted) {
        setState(() => _resendSecondsLeft = next.resendAfterSeconds);
        _tickResend();
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppNotice.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.all(t.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authOtpTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: t.space8),
              Text(
                l10n.authOtpSentTo(widget.email),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: t.space24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: l10n.authOtpLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(),
              ),
              SizedBox(height: t.space16),
              EnjoyButton.primary(
                onPressed: _busy ? null : _verify,
                child: Text(l10n.authVerifyOtp),
              ),
              SizedBox(height: t.space12),
              EnjoyButton.ghost(
                onPressed: (_busy || _resendSecondsLeft > 0) ? null : _resend,
                child: Text(
                  _resendSecondsLeft > 0
                      ? l10n.authOtpResendIn(_resendSecondsLeft)
                      : l10n.authOtpResend,
                ),
              ),
              EnjoyButton.ghost(
                onPressed: () =>
                    ref.read(authCtrlProvider.notifier).cancelSignIn(),
                child: Text(l10n.authCancel),
              ),
            ],
          ),
        ),
      ),
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
