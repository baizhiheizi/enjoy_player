/// Application shell: adaptive navigation + page stack + global transport.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/root_shell_bottom_inset.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/player_controller.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/global_transport_bar.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _navIndexForPath(String path) {
    if (path.startsWith('/settings')) return 3;
    if (path.startsWith('/cloud')) return 2;
    if (path.startsWith('/library')) return 1;
    return 0;
  }

  void _goNavIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/library');
        return;
      case 2:
        context.go('/cloud');
        return;
      case 3:
        context.go('/settings');
        return;
      default:
        context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncCtrlProvider);
    final sessionActive =
        ref.watch(playerControllerProvider.select((s) => s != null));
    final l10n = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');

    return AppBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tokens = EnjoyThemeTokens.of(context);
          final useSidebar =
              constraints.maxWidth >= tokens.breakpointRail && !onPlayer;

          final pageColumn = Column(
            children: [
              Expanded(child: widget.child),
              if (sessionActive) const GlobalTransportBar(),
              if (!useSidebar && !onPlayer)
                NavigationBar(
                  selectedIndex: _navIndexForPath(path),
                  onDestinationSelected: (i) {
                    Haptics.selection(context);
                    _goNavIndex(context, i);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: l10n.homeTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.collections_bookmark_outlined),
                      selectedIcon: const Icon(Icons.collections_bookmark_rounded),
                      label: l10n.libraryTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.cloud_outlined),
                      selectedIcon: const Icon(Icons.cloud_rounded),
                      label: l10n.cloudScreenTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: l10n.settingsTitle,
                    ),
                  ],
                ),
            ],
          );

          final bottomClearance =
              (sessionActive ? kRootShellTransportSnackClearance : 0.0) +
              (!useSidebar && !onPlayer ? kRootShellBottomNavSnackClearance : 0.0);

          if (useSidebar) {
            return RootShellBottomInset(
              bottomClearance: bottomClearance,
              child: Scaffold(
                body: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        container: true,
                        label: l10n.navMainLabel,
                        child: const AppSidebar(),
                      ),
                      Expanded(child: pageColumn),
                    ],
                  ),
                ),
              ),
            );
          }

          return RootShellBottomInset(
            bottomClearance: bottomClearance,
            child: Scaffold(body: SafeArea(child: pageColumn)),
          );
        },
      ),
    );
  }
}
