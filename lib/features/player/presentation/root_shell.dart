/// Application shell: adaptive navigation + page stack + mini player.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/player_controller.dart';
import '../application/player_ui_provider.dart';
import 'mini_player_bar.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;

  void _attachPlayerStreams() {
    final session = ref.read(playerControllerProvider);
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _playingSub = null;
    _bufferingSub = null;
    if (session == null) return;

    final player = ref.read(playerControllerProvider.notifier).player;
    _playingSub = player.stream.playing.listen((v) {
      ref.read(playerUiProvider.notifier).setPlaying(v);
    });
    _bufferingSub = player.stream.buffering.listen((v) {
      ref.read(playerUiProvider.notifier).setBuffering(v);
    });
  }

  int _navIndexForPath(String path) {
    if (path.startsWith('/settings')) return 1;
    return 0;
  }

  void _goNavIndex(BuildContext context, int index) {
    if (index == 0) {
      context.go('/');
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerControllerProvider, (previous, next) {
      if (previous?.mediaId != next?.mediaId || (previous == null) != (next == null)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _attachPlayerStreams());
      }
    });

    final session = ref.watch(playerControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');

    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = EnjoyThemeTokens.of(context);
        final useRail =
            constraints.maxWidth >= tokens.breakpointRail && !onPlayer;

        final content = Column(
          children: [
            Expanded(child: widget.child),
            if (session != null) const MiniPlayerBar(),
            if (!onPlayer && !useRail)
              NavigationBar(
                selectedIndex: _navIndexForPath(path),
                onDestinationSelected: (i) => _goNavIndex(context, i),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.library_music_outlined),
                    selectedIcon: const Icon(Icons.library_music_rounded),
                    label: l10n.libraryTitle,
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

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    container: true,
                    label: l10n.navMainLabel,
                    child: NavigationRail(
                      selectedIndex: _navIndexForPath(path),
                      onDestinationSelected: (i) => _goNavIndex(context, i),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_music_outlined),
                          selectedIcon: const Icon(Icons.library_music_rounded),
                          label: Text(l10n.libraryTitle),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings_rounded),
                          label: Text(l10n.settingsTitle),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).dividerTheme.color,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        return Scaffold(body: SafeArea(child: content));
      },
    );
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    super.dispose();
  }
}
