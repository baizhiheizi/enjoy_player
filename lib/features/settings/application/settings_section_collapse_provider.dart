/// Per-section expand/collapse state for the single-column Settings layout.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';

/// Ephemeral (resets each app launch, per research.md decision #3) map of
/// sectionId → collapsed. Seeded from [SettingsEntryDescriptor.collapsedByDefault].
final settingsSectionCollapseProvider =
    NotifierProvider<SettingsSectionCollapseNotifier, Map<String, bool>>(
      SettingsSectionCollapseNotifier.new,
    );

class SettingsSectionCollapseNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {
      for (final d in kSettingsRegistry.where((d) => d.isSectionHeader))
        d.sectionId: d.collapsedByDefault,
    };
  }

  bool isCollapsed(String sectionId) => state[sectionId] ?? false;

  void toggle(String sectionId) {
    final next = Map<String, bool>.of(state);
    next[sectionId] = !(next[sectionId] ?? false);
    state = next;
  }

  void setCollapsed(String sectionId, bool collapsed) {
    if ((state[sectionId] ?? false) == collapsed) return;
    final next = Map<String, bool>.of(state);
    next[sectionId] = collapsed;
    state = next;
  }
}
