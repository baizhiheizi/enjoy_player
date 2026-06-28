/// Read-only list of shortcuts (web `HotkeysHelpModal` parity) — premium cheatsheet.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_filter.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeysHelpDialog extends ConsumerStatefulWidget {
  const HotkeysHelpDialog({super.key});

  @override
  ConsumerState<HotkeysHelpDialog> createState() => _HotkeysHelpDialogState();
}

List<HotkeyDefinition> _hotkeyDefinitionsForScope(HotkeyScope scope) =>
    hotkeyDefinitions.where((d) => d.scope == scope).toList();

class _HotkeysHelpDialogState extends ConsumerState<HotkeysHelpDialog> {
  final _search = TextEditingController();
  final _focus = FocusNode(debugLabel: 'hotkeys-help');

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.watch(hotkeysCtrlProvider);
    final ctrl = ref.read(hotkeysCtrlProvider.notifier);
    final helpKeyLabel = formatHotkeyForDisplay(
      ctrl.effectiveKeys('global.help'),
    );

    String effective(String id) => ctrl.effectiveKeys(id);

    bool matches(HotkeyDefinition d) =>
        hotkeyDefinitionMatchesQuery(d, _search.text, l10n, effective);

    return Dialog(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            hotkeysCheatsheetOpen.value = false;
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(t.radiusMd),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(t.space12),
                        child: Icon(
                          Icons.keyboard_outlined,
                          color: cs.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: t.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.hotkeysTitle,
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: t.space4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.hotkeysHelpSubtitle(helpKeyLabel),
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              KbdChordRow(
                                binding: ctrl.effectiveKeys('global.help'),
                                compact: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonLabel,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: t.space16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.hotkeysHelpSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
                SizedBox(height: t.space16),
                Expanded(
                  child: _HotkeysHelpList(
                    matches: matches,
                    ctrl: ctrl,
                    l10n: l10n,
                  ),
                ),
                SizedBox(height: t.space12),
                Text(
                  l10n.hotkeysHintFooter,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      unawaited(router.push('/settings/keyboard'));
                    },
                    child: Text(l10n.hotkeysHelpCustomize),
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

class _HotkeysHelpList extends StatelessWidget {
  const _HotkeysHelpList({
    required this.matches,
    required this.ctrl,
    required this.l10n,
  });

  final bool Function(HotkeyDefinition def) matches;
  final HotkeysCtrl ctrl;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final children = <Widget>[];
    var any = false;
    for (final scope in HotkeyScope.values) {
      final defs = _hotkeyDefinitionsForScope(scope).where(matches).toList();
      if (defs.isEmpty) continue;
      any = true;
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: t.space8),
          child: Text(
            hotkeysScopeLabel(l10n, scope).toUpperCase(),
            style: tt.labelSmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
      );
      for (final def in defs) {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: t.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: t.space8,
                    runSpacing: t.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(hotkeyDescription(l10n, def), style: tt.bodyMedium),
                      if (ctrl.hasCustomBinding(def.id))
                        Chip(
                          label: Text(
                            l10n.hotkeysCustomizedBadge,
                            style: tt.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: EdgeInsets.symmetric(
                            horizontal: t.space8,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: t.space16),
                KbdChordRow(binding: ctrl.effectiveKeys(def.id)),
              ],
            ),
          ),
        );
      }
      children.add(SizedBox(height: t.space8));
    }

    if (!any) {
      return Center(
        child: Text(
          l10n.hotkeysHelpEmpty,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    // Reserve trailing space so desktop scrollbars do not paint over key caps.
    final trailingPad = t.space16 + 12;

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(end: trailingPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Opens the cheatsheet and keeps [hotkeysCheatsheetOpen] in sync for `?` toggle.
Future<void> showHotkeysHelpDialog(BuildContext context) {
  hotkeysCheatsheetOpen.value = true;
  return showEnjoyDialog<void>(
    context: context,
    builder: (ctx) => const HotkeysHelpDialog(),
  ).whenComplete(() {
    hotkeysCheatsheetOpen.value = false;
  });
}
