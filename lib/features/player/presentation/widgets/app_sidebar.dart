/// Primary navigation sidebar — flat tonal panel with hairline border.
/// Glass is intentionally absent here; it lives only on the transport bar.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sidebar_account_chip.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../library/application/library_search_focus.dart';
import '../../../library/application/library_search_focus_provider.dart';
import '../../../library/application/library_search_provider.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  late final TextEditingController _searchController;
  FocusNode? _attachedSearchFocusNode;
  VoidCallback? _searchFocusListener;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(librarySearchProvider),
    );
  }

  @override
  void dispose() {
    _detachSearchFocusListener();
    _searchController.dispose();
    super.dispose();
  }

  void _detachSearchFocusListener() {
    if (_searchFocusListener != null && _attachedSearchFocusNode != null) {
      _attachedSearchFocusNode!.removeListener(_searchFocusListener!);
    }
    _searchFocusListener = null;
    _attachedSearchFocusNode = null;
  }

  void _attachSearchFocusListener(FocusNode node) {
    if (identical(node, _attachedSearchFocusNode)) return;
    _detachSearchFocusListener();
    _attachedSearchFocusNode = node;
    _searchFocusListener = () {
      if (!node.hasFocus || !mounted) return;
      ensureLibraryRouteForSearch(GoRouter.of(context));
    };
    node.addListener(_searchFocusListener!);
  }

  @override
  Widget build(BuildContext context) {
    final searchFocusNode = ref.watch(librarySearchFocusNodeProvider);
    _attachSearchFocusListener(searchFocusNode);

    ref.listen(librarySearchFocusRequestProvider, (previous, next) {
      searchFocusNode.requestFocus();
    });

    ref.listen(librarySearchProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final path = GoRouterState.of(context).uri.path;
    final searchTooltip = hotkeyTooltipLabel(
      ref,
      'library.search',
      l10n.hotkeysDescLibrarySearch,
    );

    return SizedBox(
      width: t.sidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop && defaultTargetPlatform == TargetPlatform.macOS)
                SizedBox(height: t.space8),
              // Brand row
              SizedBox(
                height: t.sidebarBrandHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.space20),
                  child: Row(
                    children: [
                      const EnjoyLogo(size: 30),
                      SizedBox(width: t.space12),
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space12,
                  0,
                  t.space12,
                  t.space12,
                ),
                child: Tooltip(
                  message: searchTooltip,
                  child: TextField(
                    focusNode: searchFocusNode,
                    controller: _searchController,
                    onTap: () =>
                        ensureLibraryRouteForSearch(GoRouter.of(context)),
                    onChanged: (v) =>
                        ref.read(librarySearchProvider.notifier).setQuery(v),
                    onSubmitted: (_) =>
                        ref.read(librarySearchProvider.notifier).commit(),
                    style: tt.bodyMedium,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(t.radiusSm),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: t.space12,
                        vertical: t.space8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              // Nav items
              _SidebarNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.homeTitle,
                selected: path == '/',
                onTap: () => context.go('/'),
              ),
              _SidebarNavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore_rounded,
                label: l10n.discoverTitle,
                selected: path.startsWith('/discover'),
                onTap: () => context.go('/discover'),
              ),
              _SidebarNavItem(
                icon: Icons.collections_bookmark_outlined,
                selectedIcon: Icons.collections_bookmark_rounded,
                label: l10n.libraryTitle,
                selected:
                    path.startsWith('/library') || path.startsWith('/cloud'),
                onTap: () => context.go('/library'),
              ),

              const Spacer(),

              // Account + Settings at bottom
              const SidebarAccountChip(),
              Padding(
                padding: EdgeInsets.only(bottom: t.space8),
                child: _SidebarNavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: l10n.settingsTitle,
                  selected: path.startsWith('/settings'),
                  onTap: () => context.go('/settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: 2),
      child: Focus(
        child: Builder(
          builder: (focusContext) {
            final focused = Focus.of(focusContext).hasFocus;
            return Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusFull),
                side: focused && !selected
                    ? BorderSide(
                        color: cs.primary.withValues(alpha: 0.55),
                        width: t.focusRingWidth,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  Haptics.selection(context);
                  onTap();
                },
                borderRadius: BorderRadius.circular(t.radiusFull),
                hoverColor: cs.onSurface.withValues(alpha: 0.06),
                splashColor: cs.primary.withValues(alpha: 0.10),
                highlightColor: cs.primary.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: t.motionFast,
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primaryContainer.withValues(alpha: 0.6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(t.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        size: 22,
                        color: selected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      SizedBox(width: t.space12),
                      Expanded(
                        child: Text(
                          label,
                          style: tt.labelLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
