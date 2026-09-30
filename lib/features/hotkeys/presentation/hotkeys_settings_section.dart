/// Settings rows for customizing shortcuts (Drift-backed via [HotkeysCtrl]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_capture_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_filter.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_search_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Tile glyph and tint for a scope's group header.
({IconData icon, Color tint}) _scopeVisuals(HotkeyScope scope) =>
    switch (scope) {
      HotkeyScope.global => (icon: EnjoyIcons.compass, tint: EnjoyTint.indigo),
      HotkeyScope.player => (icon: EnjoyIcons.playCircle, tint: EnjoyTint.iris),
      HotkeyScope.library => (icon: EnjoyIcons.book, tint: EnjoyTint.orange),
      HotkeyScope.modal => (icon: EnjoyIcons.keyboard, tint: EnjoyTint.slate),
    };

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
      SettingsSearchInput(
        controller: _filter,
        hint: l10n.hotkeysFilterHint,
        clearTooltip: l10n.settingsSearchClear,
        hasQuery: _filter.text.isNotEmpty,
        onChanged: (_) => setState(() {}),
        onClear: () => setState(_filter.clear),
      ),
      SizedBox(height: t.space16),
    ];

    var groupCount = 0;
    for (final scope in HotkeyScope.values) {
      final defs = _definitionsFor(scope).where(matches).toList();
      if (defs.isEmpty) continue;
      final visuals = _scopeVisuals(scope);

      if (groupCount > 0) children.add(SizedBox(height: t.space24));
      groupCount++;

      children.add(
        Row(
          children: [
            EnjoyIconTile(
              icon: visuals.icon,
              color: visuals.tint,
              size: kSettingsRowLeadingSize,
            ),
            const SizedBox(width: kSettingsRowLeadingGap),
            Expanded(
              child: EnjoySectionHeader(
                title: hotkeysScopeLabel(l10n, scope),
                caption: '${defs.length}',
              ),
            ),
          ],
        ),
      );
      children.add(SizedBox(height: t.space12));
      children.add(
        EnjoyCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < defs.length; i++) ...[
                if (i > 0) const SettingsRowDivider(insetForLeading: false),
                _HotkeyEditRow(
                  description: hotkeyDescription(l10n, defs[i]),
                  customized: ctrl.hasCustomBinding(defs[i].id),
                  customizedLabel: l10n.hotkeysCustomizedBadge,
                  binding: ctrl.effectiveKeys(defs[i].id),
                  editTooltip: l10n.hotkeysEditTooltip,
                  resetTooltip: l10n.hotkeysResetTooltip,
                  onEdit: () => editBinding(defs[i].id),
                  onReset: ctrl.hasCustomBinding(defs[i].id)
                      ? () => ctrl.resetBinding(defs[i].id)
                      : null,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (groupCount == 0) {
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

/// Edge of the trailing edit / reset action buttons in a hotkey row.
const double kHotkeyRowActionSize = 30;

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

    return EnjoyPressable(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(t.radiusMd),
      pressedScale: kSettingsRowPressedScale,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: t.space8,
          horizontal: t.space12,
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
                    EnjoyTierBadge(label: customizedLabel, muted: true),
                ],
              ),
            ),
            SizedBox(width: t.space12),
            KbdChordRow(binding: binding, compact: true),
            SizedBox(width: t.space8),
            EnjoyIconButton(
              icon: EnjoyIcons.tune,
              onPressed: onEdit,
              tooltip: editTooltip,
              size: kHotkeyRowActionSize,
            ),
            SizedBox(width: t.space8),
            EnjoyIconButton(
              icon: EnjoyIcons.refresh,
              onPressed: onReset,
              tooltip: resetTooltip,
              size: kHotkeyRowActionSize,
            ),
          ],
        ),
      ),
    );
  }
}
