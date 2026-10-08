/// Library search field (the `Library` board): paper, 40px, `/` keycap when
/// empty, clear button while searching. Without the desktop sidebar it also
/// answers the `/` focus request.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/features/library/application/library_search_focus_provider.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _kSearchHeight = 40;

class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({super.key});

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
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
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(librarySearchProvider);
    final focusNode = ref.watch(libraryCompactSearchFocusNodeProvider);
    final hasSidebar = MediaQuery.sizeOf(context).width >= t.breakpointCompact;

    ref.listen(librarySearchProvider, (previous, next) {
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });
    ref.listen(librarySearchFocusRequestProvider, (previous, next) {
      if (!hasSidebar) focusNode.requestFocus();
    });

    return SizedBox(
      height: _kSearchHeight,
      child: TextField(
        expands: true,
        maxLines: null,
        focusNode: focusNode,
        controller: _controller,
        onChanged: (v) => ref.read(librarySearchProvider.notifier).setQuery(v),
        onSubmitted: (_) => ref.read(librarySearchProvider.notifier).commit(),
        style: tt.bodyMedium?.copyWith(fontSize: 14, color: t.ink),
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: l10n.librarySearchHint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          prefixIcon: Icon(EnjoyIcons.search, color: t.ink3, size: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: query.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Center(widthFactor: 1, child: EnjoyKeycap(label: '/')),
                )
              : Tooltip(
                  message: l10n.librarySearchClear,
                  child: EnjoyPressable(
                    onTap: () =>
                        ref.read(librarySearchProvider.notifier).clear(),
                    borderRadius: BorderRadius.circular(7),
                    child: Icon(EnjoyIcons.close, size: 15, color: t.ink3),
                  ),
                ),
        ),
      ),
    );
  }
}
