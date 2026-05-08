/// WMP-style primary navigation: brand, search, Home / Library, Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../library/application/library_search_focus_provider.dart';
import '../../../library/application/library_search_provider.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;

    return SizedBox(
      width: t.sidebarWidth,
      child: GlassSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: t.sidebarBrandHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space20),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, color: cs.primary, size: 28),
                    SizedBox(width: t.space12),
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(t.space16, 0, t.space16, t.space12),
              child: TextField(
                focusNode: ref.watch(librarySearchFocusNodeProvider),
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(librarySearchProvider.notifier).setQuery(v),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 22),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: t.space12,
                    vertical: t.space12,
                  ),
                  isDense: true,
                ),
              ),
            ),
            _SidebarNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: l10n.homeTitle,
              selected: path == '/',
              onTap: () => context.go('/'),
            ),
            _SidebarNavItem(
              icon: Icons.library_music_outlined,
              selectedIcon: Icons.library_music_rounded,
              label: l10n.libraryTitle,
              selected: path.startsWith('/library'),
              onTap: () => context.go('/library'),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: t.space12),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.radiusSm),
          child: AnimatedContainer(
            duration: t.motionFast,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: t.space12,
              vertical: t.space12,
            ),
            decoration: BoxDecoration(
              color: selected ? cs.secondaryContainer.withValues(alpha: 0.55) : null,
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: Border(
                left: BorderSide(
                  color: selected ? cs.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color:
                      selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
                SizedBox(width: t.space12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
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
