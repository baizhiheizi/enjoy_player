/// Settings rows for customizing shortcuts (Drift-backed via [HotkeysCtrl]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_capture_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_filter.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeysSettingsSection extends ConsumerStatefulWidget {
  const HotkeysSettingsSection({super.key});

  @override
  ConsumerState<HotkeysSettingsSection> createState() =>
      _HotkeysSettingsSectionState();
}

class _HotkeysSettingsSectionState extends ConsumerState<HotkeysSettingsSection> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<HotkeyDefinition> _definitionsFor(HotkeyScope scope) =>
      hotkeyDefinitions
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
    final helpKeyLabel = formatHotkeyForDisplay(ctrl.effectiveKeys('global.help'));

    String effective(String id) => ctrl.effectiveKeys(id);

    bool matches(HotkeyDefinition d) => hotkeyDefinitionMatchesQuery(
          d,
          _filter.text,
          l10n,
          effective,
        );

    Future<void> editBinding(String id) async {
      final chord = await showDialog<String>(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hotkeysSectionKeyboard,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: t.space4),
                  Text(
                    l10n.hotkeysSettingsSubtitle(helpKeyLabel),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await ctrl.resetAllBindings();
              },
              child: Text(l10n.hotkeysResetAll),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        TextField(
          controller: _filter,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.hotkeysFilterHint,
            prefixIcon: const Icon(Icons.filter_list_rounded),
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: t.space16),
        for (final scope in HotkeyScope.values) ...[
          Builder(
            builder: (context) {
              final defs = _definitionsFor(scope).where(matches).toList();
              if (defs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  for (final def in defs)
                    Padding(
                      padding: EdgeInsets.only(bottom: t.space4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(t.radiusMd),
                          onTap: () => editBinding(def.id),
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
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        hotkeyDescription(l10n, def),
                                        style: tt.bodyMedium,
                                      ),
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
                                KbdChordRow(
                                  binding: ctrl.effectiveKeys(def.id),
                                  compact: true,
                                ),
                                IconButton(
                                  tooltip: l10n.hotkeysEditTooltip,
                                  icon: const Icon(Icons.tune_rounded),
                                  onPressed: () => editBinding(def.id),
                                ),
                                IconButton(
                                  tooltip: l10n.hotkeysResetTooltip,
                                  onPressed: ctrl.hasCustomBinding(def.id)
                                      ? () => ctrl.resetBinding(def.id)
                                      : null,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: t.space12),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
