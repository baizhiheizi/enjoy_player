/// Primary navigation sidebar — Duet ground with a right line, brand row,
/// search, nav rows, and the account footer (ADR-0093).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/core/theme/widgets/nav_item_pill.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sidebar_account_chip.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
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

  String _effectiveKey(String hotkeyId, String fallback) {
    if (!isDesktop) return fallback;
    final keys = formatHotkeyForDisplay(
      ref.read(hotkeysCtrlProvider.notifier).effectiveKeys(hotkeyId),
    );
    return keys.isEmpty ? fallback : keys;
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
    final tt = Theme.of(context).textTheme;
    final path = GoRouterState.of(context).uri.path;
    final searchTooltip = hotkeyTooltipLabel(
      ref,
      'library.search',
      l10n.hotkeysDescLibrarySearch,
    );
    final searchKeys = _effectiveKey('library.search', '/');
    final craftKey = _effectiveKey('global.craft', 'C');
    final due = ref.watch(vocabularyStatsProvider).due;

    OutlineInputBorder searchBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusControl - 1),
          borderSide: BorderSide(color: color, width: width),
        );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: t.sidebarWidth,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: t.line)),
        ),
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop && defaultTargetPlatform == TargetPlatform.macOS)
                  const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const EnjoyLogo(size: 22),
                        const SizedBox(width: 10),
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
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Tooltip(
                    message: searchTooltip,
                    child: SizedBox(
                      height: 38,
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
                            onTap: () => ensureLibraryRouteForSearch(
                              GoRouter.of(context),
                            ),
                            onChanged: (v) => ref
                                .read(librarySearchProvider.notifier)
                                .setQuery(v),
                            onSubmitted: (_) => ref
                                .read(librarySearchProvider.notifier)
                                .commit(),
                            style: tt.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              color: t.ink,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: l10n.librarySearchHint,
                              hintStyle: tt.bodyMedium?.copyWith(
                                fontSize: 13.5,
                                color: t.ink3,
                              ),
                              prefixIcon: Icon(
                                EnjoyIcons.search,
                                color: t.ink3,
                                size: 16,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 38,
                              ),
                              suffixIcon: showKeycap
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Center(
                                        widthFactor: 1,
                                        child: EnjoyKeycap(label: searchKeys),
                                      ),
                                    )
                                  : null,
                              suffixIconConstraints: const BoxConstraints(
                                minHeight: 38,
                              ),
                              filled: true,
                              fillColor: t.paper,
                              border: searchBorder(Colors.transparent),
                              enabledBorder: searchBorder(t.line),
                              focusedBorder: searchBorder(t.brandInk, 1.5),
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
                  ),
                  label: l10n.libraryTitle,
                  selected:
                      path.startsWith('/library') || path.startsWith('/cloud'),
                  onTap: () => context.go('/library'),
                ),
                NavItemPill(
                  icon: EnjoyIcons.book,
                  label: l10n.vocabularyTitle,
                  selected: path.startsWith('/vocabulary'),
                  onTap: () => context.go('/vocabulary'),
                  trailing: due > 0 ? _DueBadge(count: due) : null,
                ),
                NavItemPill(
                  icon: EnjoyIcons.edit,
                  label: l10n.craftScreenTitle,
                  selected: path.startsWith('/craft'),
                  onTap: () => context.go('/craft'),
                  trailing: EnjoyKeycap(label: craftKey),
                ),

                const Spacer(),

                const _SyncStatusLine(),
                NavItemPill(
                  icon: EnjoyIcons.gear,
                  iconWidget: const EnjoyChromeIcon(EnjoyChromeGlyph.gear),
                  selectedIconWidget: const EnjoyChromeIcon(
                    EnjoyChromeGlyph.gear,
                  ),
                  label: l10n.settingsTitle,
                  selected: path.startsWith('/settings'),
                  onTap: () => context.go('/settings'),
                ),
                SidebarAccountChip(selected: path.startsWith('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: t.youSoft,
        shape: const StadiumBorder(),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: enjoyMonoStyle(
          context,
          size: 11,
          weight: FontWeight.w600,
          color: t.youInk,
          height: 1,
        ),
        maxLines: 1,
      ),
    );
  }
}

class _SyncStatusLine extends ConsumerWidget {
  const _SyncStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);
    final signedIn = auth.asData?.value is AuthSignedIn;
    if (!signedIn) return const SizedBox.shrink();

    final snapshot = ref.watch(syncQueueSnapshotProvider);
    final pending = snapshot.asData?.value.retryablePending ?? 0;
    final failed = snapshot.asData?.value.permanentlyFailed ?? 0;
    final upToDate = pending == 0 && failed == 0;
    final label = upToDate
        ? l10n.syncSettingsTileSubtitleUpToDate
        : l10n.syncSettingsTileSubtitleCounts(pending, failed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: EnjoyPressable(
        onTap: () => context.go('/settings/sync'),
        borderRadius: BorderRadius.circular(t.radiusControl - 1),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  EnjoyIcons.check,
                  size: 14,
                  color: upToDate ? t.originalInk : t.ink3,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12.5,
                      color: t.ink3,
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
