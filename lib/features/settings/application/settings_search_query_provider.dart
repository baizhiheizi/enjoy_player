/// Current text typed into the Settings hub search field.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors the shape of `librarySearchProvider` — synchronous, undebounced
/// (the Settings registry is tiny, so filtering on every keystroke is cheap;
/// see research.md decision #1).
final settingsSearchQueryProvider =
    NotifierProvider<SettingsSearchQueryNotifier, String>(
      SettingsSearchQueryNotifier.new,
    );

class SettingsSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}
