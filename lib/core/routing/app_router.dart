/// go_router configuration with persistent shell (mini player).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/routing/auth_router_tick.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_screen.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/profile_screen.dart';
import 'package:enjoy_player/features/auth/presentation/sign_in_screen.dart';
import 'package:enjoy_player/features/cloud/presentation/cloud_screen.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/sync_status_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authTick = ref.watch(authRouterTickProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authTick,
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
      if (loc.startsWith('/sign-in')) {
        if (v is AuthSignedIn) return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/cloud',
            builder: (context, state) => const CloudScreen(),
          ),
          GoRoute(
            path: '/player/:mediaId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['mediaId']!;
              return CustomTransitionPage<void>(
                key: state.pageKey,
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
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/sync',
            builder: (context, state) => const SyncStatusScreen(),
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
            path: '/sign-in',
            builder: (context, state) => const SignInScreen(),
          ),
        ],
      ),
    ],
  );
}
