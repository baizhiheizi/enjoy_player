/// Search field for the Settings hub — filters rows/sections as you type.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsSearchField extends ConsumerStatefulWidget {
  const SettingsSearchField({super.key});

  @override
  ConsumerState<SettingsSearchField> createState() =>
      _SettingsSearchFieldState();
}

class _SettingsSearchFieldState extends ConsumerState<SettingsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsSearchQueryProvider, (previous, next) {
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final hasQuery = ref.watch(
      settingsSearchQueryProvider.select((q) => q.isNotEmpty),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space16),
      child: TextField(
        controller: _controller,
        onChanged: (v) =>
            ref.read(settingsSearchQueryProvider.notifier).setQuery(v),
        style: tt.bodyMedium,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.settingsSearchHint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: l10n.settingsSearchClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    ref.read(settingsSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusLg),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space12,
          ),
        ),
      ),
    );
  }
}
