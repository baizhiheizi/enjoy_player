/// Settings rows for customizing shortcuts (Drift-backed via [HotkeysCtrl]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_capture_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_filter.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Trailing action icons share a fixed column so edit/reset stay aligned.
const double _kHotkeyActionsColumnWidth = 80;

class HotkeysSettingsSection extends ConsumerStatefulWidget {
  const HotkeysSettingsSection({super.key});

  @override
  ConsumerState<HotkeysSettingsSection> createState() =>
      _HotkeysSettingsSectionState();
}

class _HotkeysSettingsSectionState
    extends ConsumerState<HotkeysSettingsSection> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<HotkeyDefinition> _definitionsFor(HotkeyScope scope) => hotkeyDefinitions
      .where((d) => d.customizable && d.scope == scope)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.watch(hotkeysCtrlProvider);
    final ctrl = ref.read(hotkeysCtrlProvider.notifier);

    String effective(String id) => ctrl.effectiveKeys(id);

    bool matches(HotkeyDefinition d) =>
        hotkeyDefinitionMatchesQuery(d, _filter.text, l10n, effective);

    Future<void> editBinding(String id) async {
      final chord = await showEnjoyDialog<String>(
        context: context,
        builder: (ctx) => const HotkeyCaptureDialog(),
      );
      if (chord == null || !context.mounted) return;
      final ok = await ctrl.setBinding(id, chord);
      if (!context.mounted) return;
      if (!ok) {
        AppNotice.error(context, l10n.hotkeysConflictError);
      }
    }

    final children = <Widget>[
      TextField(
        controller: _filter,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l10n.hotkeysFilterHint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space12,
          ),
        ),
      ),
      SizedBox(height: t.space16),
    ];

    var sectionCount = 0;
    for (final scope in HotkeyScope.values) {
      final defs = _definitionsFor(scope).where(matches).toList();
      if (defs.isEmpty) continue;
      children.add(
        Padding(
          padding: EdgeInsets.only(
            top: sectionCount > 0 ? t.space12 : 0,
            bottom: t.space8,
          ),
          child: Text(
            hotkeysScopeLabel(l10n, scope).toUpperCase(),
            style: tt.labelSmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
      sectionCount++;
      for (final def in defs) {
        children.add(
          _HotkeyEditRow(
            description: hotkeyDescription(l10n, def),
            customized: ctrl.hasCustomBinding(def.id),
            customizedLabel: l10n.hotkeysCustomizedBadge,
            binding: ctrl.effectiveKeys(def.id),
            editTooltip: l10n.hotkeysEditTooltip,
            resetTooltip: l10n.hotkeysResetTooltip,
            onEdit: () => editBinding(def.id),
            onReset: ctrl.hasCustomBinding(def.id)
                ? () => ctrl.resetBinding(def.id)
                : null,
          ),
        );
      }
    }

    if (sectionCount == 0) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: t.space24),
          child: Center(
            child: Text(
              l10n.hotkeysHelpEmpty,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _HotkeyEditRow extends StatelessWidget {
  const _HotkeyEditRow({
    required this.description,
    required this.customized,
    required this.customizedLabel,
    required this.binding,
    required this.editTooltip,
    required this.resetTooltip,
    required this.onEdit,
    required this.onReset,
  });

  final String description;
  final bool customized;
  final String customizedLabel;
  final String binding;
  final String editTooltip;
  final String resetTooltip;
  final VoidCallback onEdit;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    final actionStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: t.space4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(t.radiusMd),
          onTap: onEdit,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: t.space8,
              horizontal: t.space4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: t.space8,
                    runSpacing: t.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(description, style: tt.bodyMedium),
                      if (customized)
                        Chip(
                          label: Text(customizedLabel, style: tt.labelSmall),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: EdgeInsets.symmetric(
                            horizontal: t.space8,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: t.space12),
                KbdChordRow(binding: binding, compact: true),
                SizedBox(width: t.space8),
                SizedBox(
                  width: _kHotkeyActionsColumnWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        style: actionStyle,
                        tooltip: editTooltip,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        style: actionStyle,
                        tooltip: resetTooltip,
                        onPressed: onReset,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                      ),
                    ],
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
