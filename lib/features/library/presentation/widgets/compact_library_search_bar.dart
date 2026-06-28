/// Compact library search field for narrow layouts (below rail breakpoint).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/library/application/library_search_focus_provider.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CompactLibrarySearchBar extends ConsumerStatefulWidget {
  const CompactLibrarySearchBar({super.key});

  @override
  ConsumerState<CompactLibrarySearchBar> createState() =>
      _CompactLibrarySearchBarState();
}

class _CompactLibrarySearchBarState
    extends ConsumerState<CompactLibrarySearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(librarySearchProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(librarySearchProvider, (previous, next) {
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    ref.listen(librarySearchFocusRequestProvider, (previous, next) {
      ref.read(libraryCompactSearchFocusNodeProvider).requestFocus();
    });

    final compactFocusNode = ref.watch(libraryCompactSearchFocusNodeProvider);

    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space12),
      child: TextField(
        focusNode: compactFocusNode,
        controller: _controller,
        onChanged: (v) => ref.read(librarySearchProvider.notifier).setQuery(v),
        onSubmitted: (_) =>
            ref.read(librarySearchProvider.notifier).commit(),
        style: tt.bodyMedium,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusSm),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space8,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
