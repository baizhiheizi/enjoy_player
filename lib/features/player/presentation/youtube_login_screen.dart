/// Full-screen WebView for Google / YouTube sign-in (shared cookie jar with player WebView).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/webview/platform_webview_environment.dart';
import 'package:enjoy_player/core/webview/webview_environment_gate.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_unavailable_message.dart';
import 'package:enjoy_player/features/player/application/youtube_auth_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class YoutubeLoginScreen extends ConsumerStatefulWidget {
  const YoutubeLoginScreen({super.key});

  static const _signInUrl =
      'https://accounts.google.com/ServiceLogin'
      '?service=youtube'
      '&uilel=3'
      '&continue=https%3A%2F%2Fm.youtube.com%2F';

  @override
  ConsumerState<YoutubeLoginScreen> createState() => _YoutubeLoginScreenState();
}

class _YoutubeLoginScreenState extends ConsumerState<YoutubeLoginScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _isSigningOut = false;
  String? _currentTitle;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      unawaited(HapticFeedback.lightImpact());
      final controller = _controller;
      final environment = await ensureAppWebViewEnvironment();
      if (!mounted) return;
      await CookieManager.instance(
        webViewEnvironment: environment,
      ).deleteAllCookies();
      if (!mounted) return;
      await controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://m.youtube.com')),
      );
      if (!mounted) return;
      ref.invalidate(youtubeLoginStateProvider);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final availability = ref.watch(youtubeAvailabilityProvider).valueOrNull;

    if (availability != null && !availability.canPlay) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(EnjoyIcons.close, size: 24),
            color: colorScheme.onSurface,
            onPressed: () {
              ref.invalidate(youtubeLoginStateProvider);
              context.pop();
            },
            tooltip: l10n.youtubeLoginClose,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              youtubeUnavailableMessage(
                l10n,
                availability is YouTubeUnavailable ? availability.reason : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (availability == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(EnjoyIcons.close, size: 24),
            color: colorScheme.onSurface,
            onPressed: () {
              ref.invalidate(youtubeLoginStateProvider);
              context.pop();
            },
            tooltip: l10n.youtubeLoginClose,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(EnjoyIcons.close, size: 24),
                    color: colorScheme.onSurface,
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      ref.invalidate(youtubeLoginStateProvider);
                      context.pop();
                    },
                    tooltip: l10n.youtubeLoginClose,
                  ),
                  Expanded(
                    child: Text(
                      _currentTitle ?? l10n.youtubeLoginScreenTitle,
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
                    icon: _isSigningOut
                        ? LoadingIcon(color: colorScheme.onSurfaceVariant)
                        : const Icon(EnjoyIcons.signOut, size: 22),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: _isSigningOut ? null : _signOut,
                    tooltip: l10n.youtubeLogout,
                  ),
                ],
              ),
            ),
            if (_isLoading)
              LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: ExcludeSemantics(
                child: WebViewEnvironmentGate(
                  placeholder: const Center(child: CircularProgressIndicator()),
                  builder: (context, environment) => InAppWebView(
                    webViewEnvironment: environment,
                    initialUrlRequest: URLRequest(
                      url: WebUri(YoutubeLoginScreen._signInUrl),
                    ),
                    initialSettings: YoutubeWebViewSettings.forLogin(),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onLoadStart: (_, _) {
                      if (mounted) setState(() => _isLoading = true);
                    },
                    onLoadStop: (controller, url) async {
                      if (!mounted) return;
                      final title = await controller.getTitle();
                      setState(() {
                        _isLoading = false;
                        _currentTitle = title;
                      });
                      ref.invalidate(youtubeLoginStateProvider);
                    },
                    onTitleChanged: (_, title) {
                      if (mounted && title != null) {
                        setState(() => _currentTitle = title);
                      }
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url?.toString() ?? '';
                      if (url.contains('youtube.com') ||
                          url.contains('google.com') ||
                          url.contains('googleapis.com') ||
                          url.contains('gstatic.com') ||
                          url.contains('accounts.google')) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      return NavigationActionPolicy.CANCEL;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
