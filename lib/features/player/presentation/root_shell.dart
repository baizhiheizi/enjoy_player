/// Application shell: adaptive navigation + page stack + player-route transport.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/root_shell_bottom_inset.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_bottom_nav.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_showcase_host.dart';
import 'package:enjoy_player/features/subscription/presentation/tier_reconcile_host.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/player_controller.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/global_transport_bar.dart';
import 'widgets/player_surface_host.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _navIndexForPath(String path) {
    if (path.startsWith('/profile') || path.startsWith('/settings')) return 3;
    if (path.startsWith('/library') || path.startsWith('/cloud')) return 2;
    if (path.startsWith('/discover')) return 1;
    return 0;
  }

  void _goNavIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/discover');
        return;
      case 2:
        context.go('/library');
        return;
      case 3:
        context.go('/profile');
        return;
      default:
        context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncCtrlProvider);
    ref.watch(discoverFeedRefreshSchedulerProvider);
    final sessionActive = ref.watch(
      playerControllerProvider.select((s) => s != null),
    );
    final updateBadge = ref.watch(updateAvailableBadgeProvider);
    final l10n = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');
    final onReview = path.startsWith('/vocabulary/review');

    return OnboardingShowcaseHost(
      child: TierReconcileHost(
        child: Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final tokens = EnjoyThemeTokens.of(context);
              final useSidebar =
                  constraints.maxWidth >= tokens.breakpointRail &&
                  !onPlayer &&
                  !onReview;

              final bottomNav = (!useSidebar && !onPlayer && !onReview)
                  ? EnjoyBottomNav(
                      selectedIndex: _navIndexForPath(path),
                      onDestinationSelected: (i) => _goNavIndex(context, i),
                      destinations: [
                        EnjoyBottomNavDestination(
                          icon: EnjoyIcons.home,
                          selectedIcon: EnjoyIcons.homeFill,
                          iconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.home,
                          ),
                          selectedIconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.home,
                            filled: true,
                          ),
                          label: l10n.homeTitle,
                        ),
                        EnjoyBottomNavDestination(
                          icon: EnjoyIcons.compass,
                          selectedIcon: EnjoyIcons.compassFill,
                          iconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.compass,
                          ),
                          selectedIconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.compass,
                            filled: true,
                          ),
                          label: l10n.discoverTitle,
                        ),
                        EnjoyBottomNavDestination(
                          icon: EnjoyIcons.library,
                          selectedIcon: EnjoyIcons.library,
                          iconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.library,
                          ),
                          selectedIconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.library,
                            filled: true,
                          ),
                          label: l10n.libraryTitle,
                        ),
                        EnjoyBottomNavDestination(
                          icon: EnjoyIcons.person,
                          selectedIcon: EnjoyIcons.personFill,
                          iconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.user,
                          ),
                          selectedIconWidget: const EnjoyChromeIcon(
                            EnjoyChromeGlyph.user,
                            filled: true,
                          ),
                          label: l10n.profileTitle,
                          showBadge: updateBadge,
                          semanticsLabel: updateBadge
                              ? '${l10n.profileTitle}, ${l10n.updateAvailableBadgeSemantics}'
                              : null,
                        ),
                      ],
                    )
                  : null;

              /// `/player/...` nests a [Scaffold] inside the route. Keeping transport in a
              /// [Column] + [Expanded] sibling can yield **zero** body height on some mobile
              /// frames (nested scaffold / safe-area constraint propagation), which pins the
              /// bar under the status bar and hides video + transcript. [Scaffold] reserves
              /// space via [bottomNavigationBar] instead.
              final playerWithTransport = sessionActive && onPlayer;

              final bottomClearance = !useSidebar && !onPlayer && !onReview
                  ? rootShellBottomNavClearance(context)
                  : 0.0;

              Widget mobileShellScaffold() {
                if (playerWithTransport) {
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    extendBody: true,
                    body: SafeArea(
                      bottom: false,
                      child: SizedBox.expand(child: widget.child),
                    ),
                    bottomNavigationBar: Material(
                      type: MaterialType.transparency,
                      child: SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        minimum: EdgeInsets.fromLTRB(
                          tokens.space16,
                          tokens.space4,
                          tokens.space16,
                          tokens.space12,
                        ),
                        child: const GlobalTransportBar(),
                      ),
                    ),
                  );
                }
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  extendBody: bottomNav != null,
                  body: SafeArea(
                    bottom: false,
                    child: Padding(
                      key: const ValueKey<String>('root-shell-content'),
                      padding: EdgeInsets.only(bottom: bottomClearance),
                      child: widget.child,
                    ),
                  ),
                  bottomNavigationBar: bottomNav == null
                      ? null
                      : Material(
                          type: MaterialType.transparency,
                          child: bottomNav,
                        ),
                );
              }

              final shell = useSidebar
                  ? RootShellBottomInset(
                      bottomClearance: bottomClearance,
                      child: ColoredBox(
                        color: tokens.canvas,
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: SafeArea(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  container: true,
                                  label: l10n.navMainLabel,
                                  child: const AppSidebar(),
                                ),
                                Expanded(
                                  child: _ContentPanel(child: widget.child),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : RootShellBottomInset(
                      bottomClearance: bottomClearance,
                      child: AppBackground(child: mobileShellScaffold()),
                    );

              final parkForYoutubeLogin = path.startsWith('/youtube/login');
              return Stack(
                fit: StackFit.expand,
                children: [
                  shell,
                  PlayerSurfaceHost(forcePark: parkForYoutubeLogin),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The desktop page surface: inset from the canvas, continuous corners,
/// hairline edge, and the aurora glow pooled along its top.
class _ContentPanel extends StatelessWidget {
  const _ContentPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(t.panelRadius);
    return Padding(
      padding: EdgeInsets.fromLTRB(0, t.shellInset, t.shellInset, t.shellInset),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: cs.surface,
          shape: RoundedSuperellipseBorder(
            borderRadius: radius,
            side: BorderSide(
              color: light ? t.hairline : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          shadows: light ? t.shadowFloat : const [],
        ),
        child: ClipRSuperellipse(borderRadius: radius, child: child),
      ),
    );
  }
}
