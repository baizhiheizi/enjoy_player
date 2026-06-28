/// Unified email entry and OTP verification sign-in flow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/otp_resend.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/otp_pin_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EmailOtpSignInFlow extends ConsumerStatefulWidget {
  const EmailOtpSignInFlow({super.key});

  @override
  ConsumerState<EmailOtpSignInFlow> createState() => _EmailOtpSignInFlowState();
}

class _EmailOtpSignInFlowState extends ConsumerState<EmailOtpSignInFlow> {
  final _emailController = TextEditingController();
  final _otpKey = GlobalKey<OtpPinFieldState>();
  bool _busy = false;
  bool _otpHasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppNotice.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppNotice.error(context, AppLocalizations.of(context)!.authEmailInvalid);
      return;
    }
    await _run(() async {
      await ref.read(authCtrlProvider.notifier).sendOtp(email: email);
    });
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _otpHasError = false;
    });
    try {
      await ref.read(authCtrlProvider.notifier).verifyOtp(code: code);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _otpHasError = true);
      _otpKey.currentState?.clear();
      AppNotice.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail(AuthAwaitingOtp otp) async {
    _emailController.text = otp.email;
    ref.read(authCtrlProvider.notifier).cancelSignIn();
    _otpKey.currentState?.clear();
    if (mounted) setState(() => _otpHasError = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authCtrlProvider);
    final otp = auth.valueOrNull;
    final showOtp = otp is AuthAwaitingOtp;

    ref.listen(authCtrlProvider, (_, next) {
      if (next.valueOrNull is AuthSignedIn && context.mounted) {
        context.go('/');
      }
    });

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EnjoyThemeTokens.of(context).space32,
              vertical: EnjoyThemeTokens.of(context).space32,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: showOtp
                  ? _OtpStep(
                      key: const ValueKey<String>('otp-step'),
                      otp: otp,
                      otpFieldKey: _otpKey,
                      busy: _busy,
                      hasError: _otpHasError,
                      onVerify: _verifyOtp,
                      onChangeEmail: () => _changeEmail(otp),
                      onResend: () =>
                          _run(ref.read(authCtrlProvider.notifier).resendOtp),
                    )
                  : _EmailStep(
                      key: const ValueKey<String>('email-step'),
                      controller: _emailController,
                      busy: _busy,
                      onSubmit: _sendOtp,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpResumePane extends ConsumerWidget {
  const OtpResumePane({required this.otp, super.key});

  final AuthAwaitingOtp otp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space32,
              vertical: t.space40,
            ),
            child: EnjoyCard(
              padding: EdgeInsets.all(t.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SignInBrandHeader(compact: true),
                  SizedBox(height: t.space24),
                  Text(
                    l10n.authOtpResumeTitle,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: t.space8),
                  Text(
                    l10n.authOtpResumeSubtitle(otp.email),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: t.space24),
                  EnjoyButton.primary(
                    onPressed: () => context.push('/sign-in/email'),
                    child: Text(l10n.authOtpResumeAction),
                  ),
                  SizedBox(height: t.space8),
                  EnjoyButton.ghost(
                    onPressed: () =>
                        ref.read(authCtrlProvider.notifier).cancelSignIn(),
                    child: Text(l10n.authCancel),
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

class _SignInBrandHeader extends StatelessWidget {
  const _SignInBrandHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final size = compact ? 56.0 : 72.0;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(t.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: SvgPicture.asset('assets/logo-light.svg', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.controller,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return EnjoyCard(
      padding: EdgeInsets.all(t.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SignInBrandHeader(),
          SizedBox(height: t.space24),
          Text(
            l10n.authContinueWithEmail,
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.authEmailPrompt,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          SizedBox(height: t.space24),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
              ),
            ),
            onSubmitted: (_) => busy ? null : onSubmit(),
          ),
          SizedBox(height: t.space24),
          EnjoyButton.primary(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : Text(l10n.authSendOtp),
          ),
        ],
      ),
    );
  }
}

class _OtpStep extends StatefulWidget {
  const _OtpStep({
    super.key,
    required this.otp,
    required this.otpFieldKey,
    required this.busy,
    required this.hasError,
    required this.onVerify,
    required this.onChangeEmail,
    required this.onResend,
  });

  final AuthAwaitingOtp otp;
  final GlobalKey<OtpPinFieldState> otpFieldKey;
  final bool busy;
  final bool hasError;
  final ValueChanged<String> onVerify;
  final VoidCallback onChangeEmail;
  final Future<void> Function() onResend;

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  Timer? _timer;
  int _resendRemaining = 0;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _syncResendRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_syncResendRemaining);
    });
  }

  @override
  void didUpdateWidget(covariant _OtpStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otp.startedAt != widget.otp.startedAt ||
        oldWidget.otp.resendAfterSeconds != widget.otp.resendAfterSeconds) {
      _syncResendRemaining();
    }
  }

  void _syncResendRemaining() {
    _resendRemaining = otpResendSecondsRemaining(
      startedAt: widget.otp.startedAt,
      resendAfterSeconds: widget.otp.resendAfterSeconds,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return EnjoyCard(
      padding: EdgeInsets.all(t.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SignInBrandHeader(compact: true),
          SizedBox(height: t.space24),
          Text(
            l10n.authOtpTitle,
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: t.space16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.space12,
              vertical: t.space8,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    widget.otp.email,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: widget.busy ? null : widget.onChangeEmail,
                  child: Text(l10n.authChangeEmail),
                ),
              ],
            ),
          ),
          SizedBox(height: t.space24),
          OtpPinField(
            key: widget.otpFieldKey,
            autofocus: true,
            enabled: !widget.busy,
            hasError: widget.hasError,
            onChanged: (value) => _code = value,
            onCompleted: widget.busy ? null : widget.onVerify,
          ),
          if (widget.hasError) ...[
            SizedBox(height: t.space8),
            Text(
              l10n.error,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
          SizedBox(height: t.space24),
          EnjoyButton.primary(
            onPressed: (widget.busy || _code.length != 6)
                ? null
                : () => widget.onVerify(_code),
            child: widget.busy
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : Text(l10n.authVerifyOtp),
          ),
          SizedBox(height: t.space12),
          Center(
            child: TextButton(
              onPressed: (widget.busy || _resendRemaining > 0)
                  ? null
                  : () => widget.onResend(),
              child: Text(
                _resendRemaining > 0
                    ? l10n.authOtpResendIn(_resendRemaining)
                    : l10n.authOtpResend,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
