/// go_router configuration with persistent shell (mini player).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/routing/auth_router_tick.dart';
import 'package:enjoy_player/core/routing/not_found_screen.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_screen.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/profile_screen.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_screen.dart';
import 'package:enjoy_player/features/auth/presentation/sign_in_screen.dart';
import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/features/discover/presentation/channel_feed_screen.dart';
import 'package:enjoy_player/features/discover/presentation/discover_screen.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/player/presentation/youtube_login_screen.dart';
import 'package:enjoy_player/features/settings/presentation/hotkeys_settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/sync_status_screen.dart';

part 'app_router.g.dart';

CustomTransitionPage<void> _shellPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
  );
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authTick = ref.watch(authRouterTickProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authTick,
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authCtrlProvider);
      if (auth.isLoading || auth.hasError) return null;
      final v = auth.valueOrNull;
      if (loc.startsWith('/profile')) {
        if (v is AuthSignedOut || v == null) {
          return '/sign-in?from=profile';
        }
      }
      if (loc.startsWith('/credits')) {
        if (v is AuthSignedOut || v == null) {
          return '/sign-in?from=credits';
        }
      }
      if (loc.startsWith('/sign-in')) {
        if (v is AuthSignedIn) return '/';
      }
      if (kReleaseMode && loc.startsWith('/settings/ai-playground')) {
        return '/settings';
      }
      if (loc.startsWith('/settings/keyboard') && !isDesktop) {
        return '/settings';
      }
      if (loc == '/cloud' || loc.startsWith('/cloud/')) {
        return libraryRouteForSource(LibrarySource.cloud);
      }
      if (loc == '/settings' &&
          state.uri.queryParameters['section'] == 'keyboard') {
        return isDesktop ? '/settings/keyboard' : null;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-home'),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-discover'),
              child: const DiscoverScreen(),
            ),
            routes: [
              GoRoute(
                path: 'channel/:channelId',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  return ChannelFeedScreen(channelId: channelId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-library'),
              child: const LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/player/:mediaId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['mediaId']!;
              return CustomTransitionPage<void>(
                // Keep the player page identity stable across `/player/:id`
                // changes. Windows WebView platform views are fragile when
                // rapidly destroyed/recreated; reusing the page lets the
                // YouTube engine navigate the existing WebView instead.
                key: const ValueKey('player-page'),
                child: ExpandedPlayerScreen(mediaId: id),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 220),
                reverseTransitionDuration: const Duration(milliseconds: 180),
              );
            },
          ),
          GoRoute(
            path: '/youtube/login',
            builder: (context, state) => const YoutubeLoginScreen(),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings'),
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/sync',
            builder: (context, state) => const SyncStatusScreen(),
          ),
          GoRoute(
            path: '/settings/keyboard',
            builder: (context, state) => const HotkeysSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/ai-playground',
            builder: (context, state) => const AiPlaygroundScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/credits',
            builder: (context, state) => const CreditsUsageScreen(),
          ),
          GoRoute(
            path: '/sign-in',
            builder: (context, state) => const SignInScreen(),
            routes: [
              GoRoute(
                path: 'email',
                builder: (context, state) => const EmailEntryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
