/// Sidebar search query (filters Library).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimum delay between the user typing in the search field and the
/// downstream `libraryFilteredListsProvider` actually re-filtering. Avoids
/// re-running the in-memory scan on every keystroke when the library is
/// large.
const Duration kLibrarySearchDebounce = Duration(milliseconds: 200);

final librarySearchProvider = NotifierProvider<LibrarySearchNotifier, String>(
  LibrarySearchNotifier.new,
);

class LibrarySearchNotifier extends Notifier<String> {
  Timer? _debounce;
  String _pending = '';

  @override
  String build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return '';
  }

  /// Schedules [value] to be committed after [kLibrarySearchDebounce].
  /// Subsequent calls inside the debounce window reset the timer; the
  /// latest value wins.
  void setQuery(String value) {
    _pending = value;
    _debounce?.cancel();
    _debounce = Timer(kLibrarySearchDebounce, () {
      state = _pending.trim();
    });
  }

  /// Synchronously commit the pending input (e.g. on Enter / submit).
  /// Cancels the pending debounced commit.
  void commit() {
    _debounce?.cancel();
    _debounce = null;
    state = _pending.trim();
  }

  /// Resets the search state to `''`, cancelling any pending debounce and
  /// discarding the pending buffer. Use this for the empty-state "Clear"
  /// action and any other call site that wants an immediate, unconditional
  /// reset (no need to mirror it with `setQuery('') + commit()`).
  void clear() {
    _debounce?.cancel();
    _debounce = null;
    _pending = '';
    state = '';
  }
}
