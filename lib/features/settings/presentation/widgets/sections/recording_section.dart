/// Recording (microphone) row body and picker dialog.
///
/// Extracted 1:1 from the pre-redesign `_RecordingMicTile` in
/// `settings_screen.dart`; preserves the mic picker dialog behavior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class RecordingSectionBody extends ConsumerWidget {
  const RecordingSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(recordingInputDeviceCtrlProvider).valueOrNull;
    final selected = state?.selectedDevice;
    final autoPicked = state?.autoPicked ?? true;

    final String subtitle;
    if (state == null || state.devices.isEmpty) {
      subtitle = l10n.settingsRecordingMicEmpty;
    } else if (autoPicked) {
      subtitle = selected != null
          ? l10n.settingsRecordingMicAuto(selected.label)
          : l10n.settingsRecordingMicAutoNoDevice;
    } else {
      subtitle = selected?.label ?? l10n.settingsRecordingMicEmpty;
    }

    return SettingsRow(
      leadingIcon: Icons.mic_none_rounded,
      title: l10n.settingsRecordingMicTitle,
      subtitle: subtitle,
      onTap: () async {
        await ref.read(recordingInputDeviceCtrlProvider.notifier).refresh();
        if (!context.mounted) return;
        await showRecordingMicPicker(context, ref);
      },
    );
  }
}

/// Shown from [RecordingSectionBody] and reusable from the two-pane detail
/// pane. Applies the choice via the controller and pops itself.
Future<void> showRecordingMicPicker(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final state = ref.read(recordingInputDeviceCtrlProvider).valueOrNull;
  final devices = state?.devices ?? const [];
  final selectedId = state?.selectedId;
  final autoPicked = state?.autoPicked ?? true;

  final groupValue = autoPicked ? null : selectedId;
  await showEnjoyDialog<void>(
    context: context,
    builder: (dialogCtx) {
      final t = EnjoyThemeTokens.of(dialogCtx);
      final mq = MediaQuery.sizeOf(dialogCtx);

      Future<void> apply(String? deviceId) async {
        await ref
            .read(recordingInputDeviceCtrlProvider.notifier)
            .selectDeviceId(deviceId);
        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
      }

      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.modalMaxWidthLarge),
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsRecordingMicDialogTitle,
                  style: Theme.of(
                    dialogCtx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: t.space16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: mq.height * 0.5),
                  child: SingleChildScrollView(
                    child: RadioGroup<String?>(
                      groupValue: groupValue,
                      onChanged: apply,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            title: Text(l10n.settingsRecordingMicAutoOption),
                          ),
                          if (devices.isEmpty)
                            ListTile(
                              enabled: false,
                              title: Text(l10n.settingsRecordingMicEmpty),
                            )
                          else
                            for (final d in devices)
                              RadioListTile<String?>(
                                value: d.id,
                                title: Text(
                                  d.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
