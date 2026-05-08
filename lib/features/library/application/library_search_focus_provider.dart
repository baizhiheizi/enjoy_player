/// Focus node for sidebar library search (hotkey `/`).
library;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_search_focus_provider.g.dart';

@Riverpod(keepAlive: true)
FocusNode librarySearchFocusNode(Ref ref) {
  final node = FocusNode(debugLabel: 'librarySearch');
  ref.onDispose(node.dispose);
  return node;
}
