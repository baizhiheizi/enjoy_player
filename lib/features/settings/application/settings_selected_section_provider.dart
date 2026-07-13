/// Selected rail section id in the two-pane desktop Settings layout.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';

/// Survives the single-column ⇄ two-pane breakpoint switch (see
/// contracts/settings-layout.md) so resizing the window never loses the
/// user's place.
final settingsSelectedSectionProvider =
    NotifierProvider<SettingsSelectedSectionNotifier, String>(
      SettingsSelectedSectionNotifier.new,
    );

class SettingsSelectedSectionNotifier extends Notifier<String> {
  @override
  String build() => SettingsSectionIds.cloudSync;

  void select(String sectionId) => state = sectionId;
}
