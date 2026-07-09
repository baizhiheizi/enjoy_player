/// Transcript blur (listening-focus) settings section body.
///
/// Hosts the tap-reveal hold-duration slider. Reads / writes
/// `TranscriptBlurPreferencesCtrl` via Riverpod; the persistence layer
/// (`SettingsDao`) is hit transparently by the ctrl.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptBlurSectionBody extends ConsumerWidget {
  const TranscriptBlurSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final prefs = ref.watch(transcriptBlurPreferencesProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16, vertical: t.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Discovery affordance: toggling listening-focus here flips the
          // same global state as the transport-bar button (hotkey: H).
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.transcriptBlurSettingsSectionTitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              l10n.transcriptBlurSettingsSectionHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: prefs.enabled,
            onChanged: (v) => ref
                .read(transcriptBlurPreferencesCtrlProvider.notifier)
                .setEnabled(v),
          ),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: t.space8),
              Expanded(
                child: Text(
                  l10n.transcriptBlurSettingsHoldDuration,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                '${prefs.tapRevealSeconds}s',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: t.space24 + t.space4, top: t.space4),
            child: Text(
              l10n.transcriptBlurSettingsHoldDurationHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: t.space24 + t.space4, top: t.space4),
            child: Slider(
              value: prefs.tapRevealSeconds.toDouble().clamp(
                TranscriptBlurPreferences.tapRevealSecondsMin.toDouble(),
                TranscriptBlurPreferences.tapRevealSecondsMax.toDouble(),
              ),
              min: TranscriptBlurPreferences.tapRevealSecondsMin.toDouble(),
              max: TranscriptBlurPreferences.tapRevealSecondsMax.toDouble(),
              divisions:
                  TranscriptBlurPreferences.tapRevealSecondsMax -
                  TranscriptBlurPreferences.tapRevealSecondsMin,
              label: '${prefs.tapRevealSeconds}s',
              onChanged: (v) => ref
                  .read(transcriptBlurPreferencesCtrlProvider.notifier)
                  .setTapRevealSeconds(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
