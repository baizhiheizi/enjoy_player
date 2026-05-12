/// Editorial sign-in screen — centered hero, single primary CTA, no glass card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
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
    final tt = Theme.of(context).textTheme;
    final signingIn = auth.valueOrNull is AuthSigningIn;

    ref.listen(authCtrlProvider, (_, next) {
      if (next.valueOrNull is AuthSignedIn && context.mounted) {
        context.go('/');
      }
    });

    return Scaffold(
      appBar:
          signingIn
              ? null
              : AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () {
                    final cur = ref.read(authCtrlProvider).valueOrNull;
                    if (cur is AuthSigningIn) {
                      ref.read(authCtrlProvider.notifier).cancelSignIn();
                    }
                    if (!context.mounted) return;
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
      body: auth.when(
        data: (state) {
          // ── Signed in ───────────────────────────────────────────────────
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

          // ── In-app WebView sign-in + polling ────────────────────────────
          if (state is AuthSigningIn) {
            return _SigningInWebPane(verificationUrl: state.verificationUrl);
          }

          // ── Default: sign in prompt ──────────────────────────────────────
          return Center(
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
                    // Brand icon
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
                    SizedBox(height: t.space40),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(authCtrlProvider.notifier)
                              .startSignIn();
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: Text(l10n.authSignInCta),
                      ),
                    ),
                    SizedBox(height: t.space12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        child: Text(l10n.authCancel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final t2 = EnjoyThemeTokens.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.all(t2.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
                    SizedBox(height: t2.space24),
                    Text(
                      l10n.errorNetwork,
                      textAlign: TextAlign.center,
                      style: tt.titleLarge,
                    ),
                    SizedBox(height: t2.space8),
                    Text(
                      '$e',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    SizedBox(height: t2.space24),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(authCtrlProvider.notifier).startSignIn();
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SigningInWebPane extends ConsumerStatefulWidget {
  const _SigningInWebPane({required this.verificationUrl});

  final String verificationUrl;

  @override
  ConsumerState<_SigningInWebPane> createState() => _SigningInWebPaneState();
}

class _SigningInWebPaneState extends ConsumerState<_SigningInWebPane> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  String? _pageTitle;

  /// Matches [YoutubeLoginScreen] — many IdPs reject default WebView UAs.
  static const _chromeMobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/134.0.0.0 Mobile Safari/537.36';

  void _onClosePressed() {
    ref.read(authCtrlProvider.notifier).cancelSignIn();
    final ctx = context;
    if (!ctx.mounted) return;
    if (ctx.canPop()) {
      ctx.pop();
    } else {
      ctx.go('/');
    }
  }

  Future<void> _reloadVerificationPage() async {
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(widget.verificationUrl)),
    );
  }

  Future<void> _openInSystemBrowser() async {
    final uri = Uri.parse(widget.verificationUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppNotice.error(
        context,
        AppLocalizations.of(context)!.playerOpenGenericError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  color: colorScheme.onSurface,
                  onPressed: _onClosePressed,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
                Expanded(
                  child: Text(
                    _pageTitle ?? l10n.authSignInTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  color: colorScheme.onSurface,
                  onPressed: _reloadVerificationPage,
                  tooltip: l10n.authReloadSignInPage,
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurface,
                  ),
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  onSelected: (value) {
                    if (value == 'browser') {
                      _openInSystemBrowser();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem<String>(
                          value: 'browser',
                          child: Text(l10n.authOpenInSystemBrowser),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.authWaitingForApproval,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              color: colorScheme.primary,
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.verificationUrl),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                thirdPartyCookiesEnabled: true,
                userAgent: _chromeMobileUserAgent,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (_, _) {
                if (mounted) setState(() => _isLoading = true);
              },
              onLoadStop: (controller, _) async {
                if (!mounted) return;
                final title = await controller.getTitle();
                setState(() {
                  _isLoading = false;
                  _pageTitle = title;
                });
              },
              onTitleChanged: (_, title) {
                if (mounted && title != null) {
                  setState(() => _pageTitle = title);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
