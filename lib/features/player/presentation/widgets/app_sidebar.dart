/// Primary navigation sidebar — sits directly on the window canvas beside the
/// floating content panel (Aurora, ADR-0089). No fill, no border: hierarchy
/// comes from the panel's lift, not from a divider.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/core/theme/widgets/nav_item_pill.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sidebar_account_chip.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../library/application/library_search_focus.dart';
import '../../../library/application/library_search_focus_provider.dart';
import '../../../library/application/library_search_provider.dart';
import '../../../library/presentation/widgets/sidebar_continue_practice_card.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachSearchFocusListener(ref.read(librarySearchFocusNodeProvider));
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
    ref.listen(librarySearchFocusNodeProvider, (_, node) {
      _attachSearchFocusListener(node);
    });

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
    final light = Theme.of(context).brightness == Brightness.light;
    final path = GoRouterState.of(context).uri.path;
    final searchTooltip = hotkeyTooltipLabel(
      ref,
      'library.search',
      l10n.hotkeysDescLibrarySearch,
    );
    final searchKeys = isDesktop
        ? formatHotkeyForDisplay(
            ref
                .read(hotkeysCtrlProvider.notifier)
                .effectiveKeys('library.search'),
          )
        : '';
    final searchRadius = BorderRadius.circular(t.radiusSm + 1);
    OutlineInputBorder searchBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: searchRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: t.sidebarWidth,
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop && defaultTargetPlatform == TargetPlatform.macOS)
                SizedBox(height: t.space8),
              SizedBox(
                height: t.sidebarBrandHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.space20),
                  child: Row(
                    children: [
                      const EnjoyLogo(size: 22),
                      SizedBox(width: t.space8 + 2),
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          style: tt.titleSmall?.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space12 - 2,
                  t.space4,
                  t.space12 - 2,
                  t.space12,
                ),
                child: Tooltip(
                  message: searchTooltip,
                  child: SizedBox(
                    height: 34,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        searchFocusNode,
                        _searchController,
                      ]),
                      builder: (context, _) {
                        final showKeycap =
                            searchKeys.isNotEmpty &&
                            !searchFocusNode.hasFocus &&
                            _searchController.text.isEmpty;
                        return TextField(
                          focusNode: searchFocusNode,
                          controller: _searchController,
                          onTap: () =>
                              ensureLibraryRouteForSearch(GoRouter.of(context)),
                          onChanged: (v) => ref
                              .read(librarySearchProvider.notifier)
                              .setQuery(v),
                          onSubmitted: (_) =>
                              ref.read(librarySearchProvider.notifier).commit(),
                          style: tt.bodyMedium?.copyWith(fontSize: 13.5),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: l10n.searchHint,
                            hintStyle: tt.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              color: t.textFaint,
                            ),
                            prefixIcon: Icon(
                              EnjoyIcons.search,
                              color: t.textFaint,
                              size: 16,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            suffixIcon: showKeycap
                                ? Padding(
                                    padding: EdgeInsets.only(right: t.space8),
                                    child: Center(
                                      widthFactor: 1,
                                      child: EnjoyKeycap(label: searchKeys),
                                    ),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 34,
                            ),
                            filled: true,
                            fillColor: light
                                ? Colors.white.withValues(alpha: 0.7)
                                : cs.onSurface.withValues(alpha: 0.055),
                            border: searchBorder(
                              light ? t.hairline : Colors.transparent,
                            ),
                            enabledBorder: searchBorder(
                              light ? t.hairline : Colors.transparent,
                            ),
                            focusedBorder: searchBorder(cs.primary, 1.5),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              NavItemPill(
                icon: EnjoyIcons.home,
                iconWidget: const EnjoyChromeIcon(EnjoyChromeGlyph.home),
                selectedIconWidget: const EnjoyChromeIcon(
                  EnjoyChromeGlyph.home,
                  filled: true,
                ),
                label: l10n.homeTitle,
                selected: path == '/',
                onTap: () => context.go('/'),
              ),
              NavItemPill(
                icon: EnjoyIcons.compass,
                iconWidget: const EnjoyChromeIcon(EnjoyChromeGlyph.compass),
                selectedIconWidget: const EnjoyChromeIcon(
                  EnjoyChromeGlyph.compass,
                  filled: true,
                ),
                label: l10n.discoverTitle,
                selected: path.startsWith('/discover'),
                onTap: () => context.go('/discover'),
              ),
              NavItemPill(
                icon: EnjoyIcons.library,
                iconWidget: const EnjoyChromeIcon(EnjoyChromeGlyph.library),
                selectedIconWidget: const EnjoyChromeIcon(
                  EnjoyChromeGlyph.library,
                  filled: true,
                ),
                label: l10n.libraryTitle,
                selected:
                    path.startsWith('/library') || path.startsWith('/cloud'),
                onTap: () => context.go('/library'),
              ),

              const Spacer(),

              const SidebarContinuePracticeCard(),

              const SidebarAccountChip(),
            ],
          ),
        ),
      ),
    );
  }
}
