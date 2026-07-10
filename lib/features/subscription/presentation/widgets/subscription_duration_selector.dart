/// Preset and custom month selection for subscription checkout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum SubscriptionDurationPreset { oneMonth, oneSeason, oneYear, custom }

const kSubscriptionSeasonMonths = 3;
const kSubscriptionYearMonths = 12;
const kSubscriptionMinCustomMonths = 1;
const kSubscriptionMaxCustomMonths = 12;

class SubscriptionDurationSelector extends StatefulWidget {
  const SubscriptionDurationSelector({
    required this.months,
    required this.onMonthsChanged,
    required this.enabled,
    super.key,
  });

  final int months;
  final ValueChanged<int> onMonthsChanged;
  final bool enabled;

  @override
  State<SubscriptionDurationSelector> createState() =>
      _SubscriptionDurationSelectorState();
}

class _SubscriptionDurationSelectorState
    extends State<SubscriptionDurationSelector> {
  late SubscriptionDurationPreset _preset;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _preset = _presetForMonths(widget.months);
    _customController = TextEditingController(text: widget.months.toString());
  }

  @override
  void didUpdateWidget(covariant SubscriptionDurationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.months != widget.months &&
        _preset != SubscriptionDurationPreset.custom) {
      _preset = _presetForMonths(widget.months);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  SubscriptionDurationPreset _presetForMonths(int months) {
    return switch (months) {
      1 => SubscriptionDurationPreset.oneMonth,
      kSubscriptionSeasonMonths => SubscriptionDurationPreset.oneSeason,
      kSubscriptionYearMonths => SubscriptionDurationPreset.oneYear,
      _ => SubscriptionDurationPreset.custom,
    };
  }

  int _monthsForPreset(SubscriptionDurationPreset preset) {
    return switch (preset) {
      SubscriptionDurationPreset.oneMonth => 1,
      SubscriptionDurationPreset.oneSeason => kSubscriptionSeasonMonths,
      SubscriptionDurationPreset.oneYear => kSubscriptionYearMonths,
      SubscriptionDurationPreset.custom => _parseCustomMonths(),
    };
  }

  int _parseCustomMonths() {
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed == null) {
      return widget.months.clamp(
        kSubscriptionMinCustomMonths,
        kSubscriptionMaxCustomMonths,
      );
    }
    return parsed.clamp(
      kSubscriptionMinCustomMonths,
      kSubscriptionMaxCustomMonths,
    );
  }

  void _selectPreset(SubscriptionDurationPreset preset) {
    if (!widget.enabled) return;
    setState(() => _preset = preset);
    if (preset == SubscriptionDurationPreset.custom) {
      _customController.text = widget.months.toString();
      widget.onMonthsChanged(_parseCustomMonths());
      return;
    }
    widget.onMonthsChanged(_monthsForPreset(preset));
  }

  void _onCustomChanged(String value) {
    if (_preset != SubscriptionDurationPreset.custom) return;
    widget.onMonthsChanged(_parseCustomMonths());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    final options = <(SubscriptionDurationPreset, String)>[
      (SubscriptionDurationPreset.oneMonth, l10n.subscriptionPurchaseOneMonth),
      (
        SubscriptionDurationPreset.oneSeason,
        l10n.subscriptionPurchaseOneSeason,
      ),
      (SubscriptionDurationPreset.oneYear, l10n.subscriptionPurchaseOneYear),
      (
        SubscriptionDurationPreset.custom,
        l10n.subscriptionPurchaseCustomDuration,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.subscriptionPurchaseDuration, style: tt.titleSmall),
        SizedBox(height: t.space8),
        Wrap(
          spacing: t.space8,
          runSpacing: t.space8,
          children: [
            for (final (preset, label) in options)
              _DurationChip(
                label: label,
                selected: _preset == preset,
                enabled: widget.enabled,
                onTap: () => _selectPreset(preset),
              ),
          ],
        ),
        if (_preset == SubscriptionDurationPreset.custom) ...[
          SizedBox(height: t.space12),
          TextField(
            controller: _customController,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.subscriptionPurchaseCustomMonthsLabel,
              hintText: l10n.subscriptionPurchaseCustomMonthsHint,
              helperText: l10n.subscriptionPurchaseCustomMonthsHelper,
            ),
            onChanged: _onCustomChanged,
          ),
        ],
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        side: BorderSide(
          color: selected
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space12,
          ),
          child: Text(
            label,
            style: tt.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
