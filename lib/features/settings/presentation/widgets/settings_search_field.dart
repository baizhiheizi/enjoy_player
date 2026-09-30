/// Search field for the Settings hub — filters rows/sections as you type.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The settings search-field treatment — a raw input with the muted leading
/// glyph, soft fill, `radiusLg` corners, and clear suffix. Callers own the
/// query state; [SettingsSearchField] wraps this with the hub's.
class SettingsSearchInput extends StatelessWidget {
  const SettingsSearchInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          EnjoyIcons.search,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: clearTooltip,
                icon: const Icon(EnjoyIcons.close, size: 18),
                onPressed: onClear,
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
    );
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    final hasQuery = ref.watch(
      settingsSearchQueryProvider.select((q) => q.isNotEmpty),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: t.space16),
      child: SettingsSearchInput(
        controller: _controller,
        hint: l10n.settingsSearchHint,
        clearTooltip: l10n.settingsSearchClear,
        hasQuery: hasQuery,
        onChanged: (v) =>
            ref.read(settingsSearchQueryProvider.notifier).setQuery(v),
        onClear: () {
          _controller.clear();
          ref.read(settingsSearchQueryProvider.notifier).clear();
        },
      ),
    );
  }
}
