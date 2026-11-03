/// Filter hotkey rows by user query (description, scope, binding).
library;

import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

bool hotkeyDefinitionMatchesQuery(
  HotkeyDefinition def,
  String rawQuery,
  AppLocalizations l10n,
  String Function(String actionId) effectiveKeys,
) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return true;

  final desc = hotkeyDescription(l10n, def).toLowerCase();
  final scopeLabel = hotkeysScopeLabel(l10n, def.scope).toLowerCase();
  final binding = effectiveKeys(def.id).toLowerCase();
  final display = formatHotkeyForDisplay(effectiveKeys(def.id)).toLowerCase();

  return desc.contains(q) ||
      scopeLabel.contains(q) ||
      binding.contains(q) ||
      display.contains(q) ||
      def.id.toLowerCase().contains(q);
}

List<(HotkeyScope, List<HotkeyDefinition>)> hotkeyScopeGroups(
  List<HotkeyDefinition> definitions, {
  required String query,
  required AppLocalizations l10n,
  required String Function(String actionId) effectiveKeys,
}) {
  bool matches(HotkeyDefinition def) =>
      hotkeyDefinitionMatchesQuery(def, query, l10n, effectiveKeys);

  return [
    for (final scope in HotkeyScope.values)
      (
        scope,
        definitions.where((d) => d.scope == scope).where(matches).toList(),
      ),
  ].where((group) => group.$2.isNotEmpty).toList();
}
